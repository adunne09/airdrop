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
            @click="handleDownloadItem(item.file)"
          >
            Download
          </a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { BigNumber, ethers } from 'ethers'
import axios from 'axios'
import Airdrop from '../../out/Airdrop.sol/Airdrop.json'
import detectEthereumProvider from '@metamask/detect-provider'
import ProgressBar from '@/components/ProgressBar.vue'

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
  claimed: boolean
  name: string
  description: string
  file: string
  role: 'sender' | 'recipient'
}

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
  items: Item[]
}

const state: Ref<State> = ref({
  loading: false,
  items: [],
})

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
      data.map(async (i: AirdropBlockchainItem) => {
        const tokenUri = await airdropContract.tokenURI(i.tokenId)
        const meta = await axios.get(tokenUri)

        return {
          tokenId: i.tokenId.toNumber(),
          sender: i.sender,
          recipient: i.recipient,
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
          role: i.sender === address ? 'sender' : 'recipient',
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
const handleDownloadItem = async (fileStr: string) => {
  // decrypt file string
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
