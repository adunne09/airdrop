<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else>
    <h2 v-if="!state.items.length">No Items Found.</h2>
    <div
      v-else
      class="grid gap-4 overflow-y-auto"
      style="grid-template-columns: repeat(3, 300px)"
    >
      <div
        class="border shadow rounded-xl overflow-hidden"
        v-for="(item, index) in state.items"
        :key="index"
      >
        <div class="p-4">
          <p class="text-2xl font-semibold h-16">{{ item.name }}</p>
          <div class="h-16 overflow-hidden">
            <p class="text-gray-400">{{ item.description }}</p>
            <p class="text-gray-400">
              {{
                item.role === 'sender'
                  ? `Recipient: ${item.recipient.slice(0, 20)}...`
                  : `Sender: ${item.sender.slice(0, 10)}...`
              }}
            </p>
          </div>
        </div>
        <div class="p-4 bg-black">
          <button
            v-if="item.role === 'recipient' && !item.claimed"
            type="button"
            class="w-full text-green-600 bg-white font-bold py-2 px-12 rounded hover:bg-green-600 hover:text-white"
            @click="handleClaimItem(item.tokenId)"
          >
            Unclaimed
          </button>
          <a
            v-else-if="item.role === 'recipient' && item.claimed"
            class="w-full text-green-600 bg-white font-bold py-2 px-12 rounded hover:bg-green-600 hover:text-white"
            @click="state.selectedItemId = item.tokenId"
          >
            Download
          </a>
        </div>
      </div>
    </div>
  </div>
  <Modal v-if="state.selectedItemId" @close="state.selectedItemId = null">
    <div style="width: 500px">
      <h2 class="flex flex-start font-bold pb-2">Decrypt file</h2>
      <form @submit.prevent="handleDownloadItem(state.selectedItemId)">
        <ProgressBar
          v-if="state.loading"
          :loading="state.loading"
          class="absolute top-60 w-4/5"
        />

        <div :class="['grid gap-4 w-full', { 'opacity-30': state.loading }]">
          <textarea
            v-model="state.formValues.recipientPrivateKey"
            name="private-key"
            placeholder="Your private key"
            class="border-2 border-pink-500 rounded p-1 resize-none"
            style="height: 300px"
          />
          <textarea
            v-model="state.formValues.senderPublicKey"
            name="public-key"
            placeholder="The sender's public key"
            class="border-2 border-pink-500 rounded p-1 resize-none"
            style="height: 300px"
          />
        </div>

        <div class="flex justify-between pt-4">
          <button
            type="button"
            class="font-bold rounded p-1 px-2 bg-pink-500 text-white cursor-pointer hover:bg-white border-2 border-pink-500 hover:text-pink-500"
            @click=""
          >
            Upload Key
          </button>

          <div class="flex gap-4">
            <button
              type="button"
              @click="state.selectedItemId = null"
              class="font-bold text-pink-500 cursor-pointer"
            >
              Cancel
            </button>
            <button
              type="submit"
              :disabled="!state.encryptedDownloadIsReady"
              :class="[
                'rounded px-2',
                state.encryptedDownloadIsReady
                  ? 'bg-pink-500 text-white cursor-pointer hover:bg-white hover:border-2 hover:border-pink-500 hover:text-pink-500'
                  : 'border-2 border-gray-400 text-gray-400 cursor-not-allowed',
              ]"
            >
              Decrypt & Download
            </button>
          </div>
        </div>
      </form>
    </div>
  </Modal>
  <a ref="downloadItemAnchor" class="hidden" />
</template>

<script setup lang="ts">
import { onMounted, computed } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { BigNumber, ethers } from 'ethers'
import axios from 'axios'
import Airdrop from '../../out/Airdrop.sol/Airdrop.json'
import detectEthereumProvider from '@metamask/detect-provider'
import ProgressBar from '@/components/ProgressBar.vue'
import Modal from '@/components/Modal.vue'
import * as openpgp from 'openpgp'

const AIRDROP_CONTRACT_ADDRESS = import.meta.env
  .VITE_APP_AIRDROP_CONTRACT_ADDRESS
const CHAIN_ID = +import.meta.env.VITE_APP_POLYGON_MUMBAI_TESTNET_CHAIN_ID // parse to int

interface AirdropBlockchainItem {
  tokenId: BigNumber
  sender: string
  recipient: string
  claimed: boolean
}

interface Item {
  tokenId: number
  sender: string
  recipient: string
  name: string
  description: string
  file: string
  claimed: boolean
  role: 'sender' | 'recipient'
  isEncrypted: boolean
  fileExtension: string
}

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
  items: Item[]

  selectedItemId: number | null
  formValues: {
    recipientPrivateKey: string
    senderPublicKey: string
  }
  encryptedDownloadIsReady: boolean
}

const state: Ref<State> = ref({
  loading: false,
  items: [],

  selectedItemId: null,
  formValues: {
    recipientPrivateKey: '',
    senderPublicKey: '',
  },
  encryptedDownloadIsReady: computed(() =>
    Boolean(
      state.value.formValues.recipientPrivateKey?.length &&
        state.value.formValues.senderPublicKey?.length
    )
  ),
})

const downloadItemAnchor: Ref<HTMLAnchorElement | null> = ref(null)

onMounted(async () => {
  state.value.loading = true

  try {
    // establish initial eth connection
    const connection = (await detectEthereumProvider()) as any
    if (!connection || connection !== window.ethereum) {
      throw new Error('Please install Metamask')
    }

    const ethereum = window.ethereum as any

    // trigger the metamask popup if the user needs to authorize connection
    const [address] = await ethereum.request({ method: 'eth_requestAccounts' })
    if (!address) {
      throw new Error('Please authorize an account to connect with')
    }

    // assert that the user is on the correct chain id
    const chainIdHex = await ethereum.request({ method: 'eth_chainId' })
    const chainId = ethers.BigNumber.from(chainIdHex).toNumber()
    if (chainId !== CHAIN_ID) {
      throw new Error('Please select the correct network')
    }

    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner(address)

    const airdropContract = new ethers.Contract(
      AIRDROP_CONTRACT_ADDRESS,
      Airdrop.abi,
      signer
    )

    const data = await airdropContract.fetchItems()

    const items: Item[] = await Promise.all(
      data.map(async (item: AirdropBlockchainItem) => {
        const tokenUri = await airdropContract.tokenURI(item.tokenId)
        const meta = await axios.get(tokenUri)

        return {
          ...item,
          tokenId: item.tokenId.toNumber(),
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
          role: item.sender === address ? 'sender' : 'recipient',
          isEncrypted: meta.data.isEncrypted, // TODO
          // fileExtension: meta.data.fileExtension, // TODO
        }
      })
    )

    state.value.items = items
  } catch (e) {
    console.error('failed to initialize;', e)
  } finally {
    state.value.loading = false
  }
})

// TODO-- add encrpytion status to ipfs metadata (isEncrypted: boolean)
const handleDownloadItem = async (id: number) => {
  try {
    const item = state.value.items.find(({ tokenId }) => tokenId === id)!

    let base64String = item.file
    if (item.isEncrypted) {
      const message = await openpgp.readMessage({
        armoredMessage: base64String,
      })

      const publicKey = await openpgp.readKey({
        armoredKey: state.value.formValues.senderPublicKey,
      })
      const privateKey = await openpgp.decryptKey({
        privateKey: await openpgp.readPrivateKey({
          armoredKey: state.value.formValues.recipientPrivateKey,
        }),
        passphrase: 'super long and hard to guess secret', // FIXME--
      })

      const { data, signatures } = await openpgp.decrypt({
        message,
        verificationKeys: publicKey,
        decryptionKeys: privateKey,
      })

      const isValidSignature = await signatures[0].verified
      console.log(isValidSignature)

      base64String = data as string
      // TODO-- set the item file as this string and isEncrypted: false
      // if they cancel, they don't have to put in the keys again
    }

    downloadItemAnchor.value!.href = base64String

    downloadItemAnchor.value!.download = `${item.name}.jpeg` // .{itme.fileExtension}
    downloadItemAnchor.value!.click()
  } catch (e) {
    console.log('failed to download item;', e)
  }
}

const handleClaimItem = async (id: number) => {
  state.value.loading = true

  try {
    // establish initial eth connection
    const connection = (await detectEthereumProvider()) as any
    if (!connection || connection !== window.ethereum) {
      throw new Error('Please install Metamask')
    }

    const ethereum = window.ethereum as any

    // trigger the metamask popup if the user needs to authorize connection
    const [address] = await ethereum.request({ method: 'eth_requestAccounts' })
    if (!address) {
      throw new Error('Please authorize an account to connect with')
    }

    // assert that the user is on the correct chain id
    const chainIdHex = await ethereum.request({ method: 'eth_chainId' })
    const chainId = ethers.BigNumber.from(chainIdHex).toNumber()
    if (chainId !== CHAIN_ID) {
      throw new Error('Please select the correct network')
    }

    const provider = new ethers.providers.Web3Provider(connection)
    const signer = provider.getSigner(address)

    const airdropContract = new ethers.Contract(
      AIRDROP_CONTRACT_ADDRESS,
      Airdrop.abi,
      signer
    )

    const transaction = await airdropContract.claimItem(id)
    await transaction.wait()

    const itemIndex = state.value.items
      .map(({ tokenId }) => tokenId)
      .indexOf(id)

    state.value.items.splice(itemIndex, 1, {
      ...state.value.items[itemIndex],
      claimed: true,
    })
  } catch (e) {
  } finally {
    state.value.loading = false
  }
}
</script>

<style scoped></style>
