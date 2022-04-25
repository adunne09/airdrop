<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else class="grid gap-4 mb-8">
    <div>
      <h2 v-if="!state.receivedItems.length">
        You haven't received any items.
      </h2>
      <div v-else>
        <router-link
          to="/received-items"
          class="flex flex-start font-bold pb-2 items-center gap-2 hover:underline"
        >
          <Status v-if="state.hasUnclaimedItems" status="pending" />
          Received Items
          <ArrowIcon class="transform rotate-180" />
        </router-link>
        <div class="flex items-center gap-4">
          <div
            class="grid gap-4 overflow-y-auto"
            style="grid-template-columns: repeat(3, 300px)"
          >
            <div
              class="border shadow rounded-xl overflow-hidden"
              v-for="(item, index) in state.receivedItems"
              :key="index"
            >
              <div class="p-4">
                <p class="text-2xl font-semibold h-12">{{ item.name }}</p>
                <div class="h-16 overflow-hidden">
                  <p class="text-gray-400">{{ item.description }}</p>
                  <p class="text-gray-400">
                    Sender: {{ `${item.sender.slice(0, 10)}...` }}
                  </p>
                </div>
                <div class="h-4">
                  <Status
                    v-if="item.senderPublicKey"
                    status="failure"
                    class="flex justify-center"
                  >
                    Encrypted
                  </Status>
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
          <ArrowIcon
            v-if="state.receivedItemsCount > 3"
            class="transform rotate-180 cursor-pointer"
            fill="#EC4899"
            @click="router.push('/received-items')"
          />
        </div>
      </div>
    </div>

    <div>
      <h2 v-if="!state.sentItems.length">You haven't sent any items.</h2>
      <div v-else>
        <router-link
          to="/sent-items"
          class="flex flex-start font-bold pb-2 items-center gap-2 hover:underline"
        >
          Sent Items
          <ArrowIcon class="transform rotate-180" />
        </router-link>
        <div class="flex items-center gap-4">
          <div
            class="grid gap-4 overflow-y-auto"
            style="grid-template-columns: repeat(3, 300px)"
          >
            <div
              class="border shadow rounded-xl overflow-hidden"
              v-for="(item, index) in state.sentItems"
              :key="index"
            >
              <div class="p-4">
                <p class="text-2xl font-semibold h-12">{{ item.name }}</p>
                <div class="h-16 overflow-hidden">
                  <p class="text-gray-400">{{ item.description }}</p>
                  <p class="text-gray-400">
                    Recipient: {{ `${item.recipient.slice(0, 10)}...` }}
                  </p>
                </div>
                <div class="h-4">
                  <Status
                    v-if="item.senderPublicKey"
                    status="failure"
                    class="flex justify-center"
                  >
                    Encrypted
                  </Status>
                </div>
              </div>
              <div class="flex p-4 bg-black justify-center">
                <Label :kind="item.claimed ? 'secondary' : 'primary'">{{
                  item.claimed ? 'Claimed' : 'Unclaimed'
                }}</Label>
              </div>
            </div>
          </div>
          <ArrowIcon
            v-if="state.sentItemsCount > 3"
            class="transform rotate-180 cursor-pointer"
            @click="router.push('/sent-items')"
          />
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
          v-if="state.encryptionValues.recipientKeyfile"
          v-model="state.encryptionValues.recipientPassphrase"
          name="key-passphrase"
          placeholder="Passphrase"
          type="password"
          autofocus
        />

        <span
          v-if="state.encryptionValues.error.length"
          class="font-bold text-red-500"
          >{{ state.encryptionValues.error }}</span
        >

        <div class="flex">
          <Button kind="text" @click="state.itemIdToDecrypt = null">
            Cancel
          </Button>
          <Button
            type="submit"
            kind="primary"
            :disabled="!state.encryptionValues.recipientPassphrase.length"
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
import Label from '@/components/Label.vue'
import Button from '@/components/Button.vue'
import Status from '@/components/Status.vue'
import ArrowIcon from '@/assets/arrow.svg?component'
import * as openpgp from 'openpgp'
import { ethUtils, fileUtils } from '../utils'
import { useRouter } from 'vue-router'

const router = useRouter()

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

  sentItems: Item[]
  sentItemsCount: number

  receivedItems: Item[]
  receivedItemsCount: number
  hasUnclaimedItems: boolean

  itemIdToDecrypt: number | null
  encryptionValues: {
    recipientKeyfile?: File
    recipientPassphrase: string

    error: string
  }
}

const state: Ref<State> = ref({
  loading: false,

  sentItems: [],
  sentItemsCount: 0,

  receivedItems: [],
  receivedItemsCount: 0,
  hasUnclaimedItems: false,

  itemIdToDecrypt: null,
  encryptionValues: {
    recipientKey: null,
    recipientPassphrase: '',
    senderKey: null,

    error: '',
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

    // address returned by metamask and address returned by contract have slightly different casing
    const receivedItems = items.filter(
      ({ recipient }) => res.address.toLowerCase() === recipient.toLowerCase()
    )
    state.value.receivedItemsCount = receivedItems.length
    state.value.receivedItems = receivedItems.slice(0, 3)
    state.value.hasUnclaimedItems = receivedItems.some(
      ({ claimed }) => !claimed
    )

    const sentItems = items.filter(
      ({ sender }) => res.address.toLowerCase() === sender.toLowerCase()
    )
    state.value.sentItemsCount = sentItems.length
    state.value.sentItems = sentItems.slice(0, 3)
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
  state.value.encryptionValues.recipientKeyfile = file
}

const handleDownloadEncryptedItem = async () => {
  try {
    if (!state.value.encryptionValues.recipientKeyfile) {
      throw new Error(
        'failed to download encypted item; recipient private key file not selected'
      )
    }

    const item = state.value.receivedItems.find(
      ({ tokenId }) => tokenId === state.value.itemIdToDecrypt
    )!

    const message = await openpgp.readMessage({
      armoredMessage: item.file,
    })

    const privateKeyStartIdentifier = '-----BEGIN PGP PRIVATE KEY BLOCK-----'
    const privateKeyEndIdentifier = '-----END PGP PRIVATE KEY BLOCK-----'

    const privateKeyRaw = (await fileUtils.parseStringFromFile(
      state.value.encryptionValues.recipientKeyfile,
      privateKeyStartIdentifier,
      privateKeyEndIdentifier
    )) as string

    const senderPrivateKey = await openpgp.decryptKey({
      privateKey: await openpgp.readPrivateKey({ armoredKey: privateKeyRaw }),
      passphrase: state.value.encryptionValues.recipientPassphrase,
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
    state.value.encryptionValues.error = ''
  } catch (e) {
    console.error('failed to download item;', e)

    if ((e as any).message?.indexOf('Incorrect key passphrase') !== -1) {
      state.value.encryptionValues.error = 'Incorrect key passphrase'
    }
  }
}

const handleClaimItem = async (id: number) => {
  const item = state.value.receivedItems.find(({ tokenId }) => tokenId === id)

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

    state.value.hasUnclaimedItems = state.value.receivedItems.some(
      ({ claimed }) => !claimed
    )
  } catch (e) {
    console.error('failed to claim item;', e)
  } finally {
    item.loading = false
  }
}
</script>

<style scoped></style>
