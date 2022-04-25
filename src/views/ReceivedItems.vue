<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else>
    <h2 v-if="!state.items.length">You haven't received any items.</h2>
    <div
      v-else
      class="grid gap-4 overflow-y-auto mb-8"
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
              Sender: {{ `${item.sender.slice(0, 10)}...` }}
            </p>
          </div>
        </div>
        <div class="flex p-4 bg-black">
          <Button
            v-if="!item.claimed"
            kind="primary"
            @click="handleClaimItem(item.tokenId)"
            :loading="item.loading"
          >
            Unclaimed
          </Button>
          <Button
            v-else-if="item.claimed"
            kind="primary"
            @click="handleDownloadItem(item)"
          >
            Download
          </Button>
        </div>
      </div>
    </div>
  </div>
  <Modal v-if="state.itemIdToDecrypt" @close="state.itemIdToDecrypt = null">
    <div style="width: 300px">
      <h2 class="flex flex-start font-bold pb-2">Decrypt file</h2>
      <form @submit.prevent="handleDownloadEncryptedItem()" class="grid gap-4">
        <ProgressBar
          v-if="state.loading"
          :loading="state.loading"
          class="absolute top-60 w-4/5"
        />

        <FileInput class="w-full" @input="handleSelectDecryptionKey($event)">
          Select Decryption Key
        </FileInput>

        <Input
          v-if="state.formValues.recipientKeyfile"
          v-model="state.formValues.recipientPassphrase"
          name="key-passphrase"
          placeholder="Passphrase"
          type="password"
          autofocus
        />

        <div class="flex">
          <Button kind="text" @click="state.itemIdToDecrypt = null">
            Cancel
          </Button>
          <Button
            type="submit"
            kind="primary"
            :disabled="!state.formValues.recipientPassphrase.length"
          >
            Decrypt
          </Button>
        </div>
      </form>
    </div>
  </Modal>
  <a ref="downloadItemAnchor" class="hidden" />
</template>

<script setup lang="ts">
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { BigNumber, ethers } from 'ethers'
import axios from 'axios'
import ProgressBar from '@/components/ProgressBar.vue'
import Modal from '@/components/Modal.vue'
import FileInput from '@/components/FileInput.vue'
import Input from '@/components/Input.vue'
import Button from '@/components/Button.vue'
import * as openpgp from 'openpgp'
import { ethUtils, fileUtils } from '../utils'

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
  senderPublicKey?: openpgp.Key
  loading?: boolean
}

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
  items: Item[]

  itemIdToDecrypt: number | null
  formValues: {
    recipientKeyfile?: File
    recipientPassphrase: string
  }
}

const state: Ref<State> = ref({
  loading: false,
  items: [],

  itemIdToDecrypt: null,
  formValues: {
    recipientKey: null,
    recipientPassphrase: '',
    senderKey: null,
  },
})

const downloadItemAnchor: Ref<HTMLAnchorElement | null> = ref(null)

const loadItems = async () => {
  state.value.loading = true

  try {
    const res = await ethUtils.establishConnectionAndGetAirdropContract()
    if (!res) {
      return
    }

    const data = await res.contract.fetchItems()

    const items: Item[] = await Promise.all(
      data.map(async (item: AirdropBlockchainItem) => {
        const tokenUri = await res.contract.tokenURI(item.tokenId)
        const meta = await axios.get(tokenUri)

        let senderPublicKey
        if (meta.data.senderPublicKey) {
          senderPublicKey = await openpgp.readKey({
            armoredKey: meta.data.senderPublicKey,
          })
        }

        return {
          ...item,
          tokenId: item.tokenId.toNumber(),
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
          senderPublicKey,
        }
      })
    )

    // only show items you've received
    // address returned by metamask and address returned by contract have slightly different casing
    state.value.items = items.filter(
      ({ recipient }) => res.address.toLowerCase() === recipient.toLowerCase()
    )
  } catch (e) {
    console.error('failed to initialize;', e)
  } finally {
    state.value.loading = false
  }
}

ethUtils.registerAccountChangeHandler(() => loadItems())

onMounted(() => loadItems())

const handleDownloadItem = (item: Item) => {
  if (item.senderPublicKey) {
    state.value.itemIdToDecrypt = item.tokenId
    return
  }

  if (!downloadItemAnchor.value) {
    console.error('failed to download item; something went wrong')
    return
  }

  downloadItemAnchor.value.href = item.file
  downloadItemAnchor.value.download = item.name
  downloadItemAnchor.value.click()
}

const handleSelectDecryptionKey = (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = (target.files as FileList)[0]
  state.value.formValues.recipientKeyfile = file
}

const handleDownloadEncryptedItem = async () => {
  try {
    if (!state.value.formValues.recipientKeyfile) {
      throw new Error(
        'failed to download encypted item; recipient private key file not selected'
      )
    }

    const item = state.value.items.find(
      ({ tokenId }) => tokenId === state.value.itemIdToDecrypt
    )!

    const message = await openpgp.readMessage({
      armoredMessage: item.file,
    })

    const privateKeyStartIdentifier = '-----BEGIN PGP PRIVATE KEY BLOCK-----'
    const privateKeyEndIdentifier = '-----END PGP PRIVATE KEY BLOCK-----'

    const privateKeyRaw = (await fileUtils.parseStringFromFile(
      state.value.formValues.recipientKeyfile,
      privateKeyStartIdentifier,
      privateKeyEndIdentifier
    )) as string

    const senderPrivateKey = await openpgp.decryptKey({
      privateKey: await openpgp.readPrivateKey({ armoredKey: privateKeyRaw }),
      passphrase: state.value.formValues.recipientPassphrase,
    })

    const { data, signatures } = await openpgp.decrypt({
      message,
      verificationKeys: item.senderPublicKey,
      decryptionKeys: senderPrivateKey,
    })

    const isValidSignature = await signatures[0].verified
    if (!isValidSignature) {
      throw new Error('failed to validate signature')
    }

    const base64String = data as string
    // TODO-- set the item file as this string and isEncrypted: false
    // if they cancel, they don't have to put in the keys again

    downloadItemAnchor.value!.href = base64String
    downloadItemAnchor.value!.download = item.name
    downloadItemAnchor.value!.click()

    state.value.itemIdToDecrypt = null
  } catch (e) {
    console.error('failed to download item;', e)
  }
}

const handleClaimItem = async (id: number) => {
  const item = state.value.items.find(({ tokenId }) => tokenId === id)

  if (!item) {
    console.error('failed to find item')
    return
  }

  item.loading = true

  try {
    const res = await ethUtils.establishConnectionAndGetAirdropContract()
    if (!res) {
      return
    }

    const transaction = await res.contract.claimItem(id)
    await transaction.wait()

    item.claimed = true
  } catch (e) {
    console.error('failed to claim item;', e)
  } finally {
    item.loading = false
  }
}
</script>

<style scoped></style>
