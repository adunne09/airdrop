<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else>
    <h2 v-if="!state.sentItems.length">You haven't sent any items.</h2>
    <div
      v-else
      class="grid gap-4 overflow-y-auto mb-8"
      style="grid-template-columns: repeat(3, 300px)"
    >
      <div
        class="border shadow rounded-xl overflow-hidden"
        v-for="(item, index) in state.sentItems"
        :key="index"
      >
        <div class="p-4">
          <p class="text-2xl font-semibold h-12">{{ item.name }}</p>
          <div class="h-16 overflow-hidden mt-2">
            <p class="text-gray-400 text-sm">{{ item.description }}</p>
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
  </div>
</template>

<script setup lang="ts">
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { BigNumber, ethers } from 'ethers'
import axios from 'axios'
import ProgressBar from '@/components/ProgressBar.vue'
import Label from '@/components/Label.vue'
import Status from '@/components/Status.vue'
import { ethUtils } from '../utils'
import { Buffer } from 'buffer/'

const IPFS_PROJECT_ID = import.meta.env.VITE_APP_IPFS_PROJECT_ID
const IPFS_PROJECT_SECRET = import.meta.env.VITE_APP_IPFS_PROJECT_SECRET

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
  loading?: boolean
  senderPublicKey: string
}

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
  sentItems: Item[]

  itemIdToDecrypt: number | null
  formValues: {
    recipientKeyfile?: File
    recipientPassphrase: string
  }
}

const state: Ref<State> = ref({
  loading: false,
  sentItems: [],

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
        const meta = await axios.post(tokenUri, undefined, {
          headers: {
            authorization: `basic ${Buffer.from(
              `${IPFS_PROJECT_ID}:${IPFS_PROJECT_SECRET}`
            ).toString('base64')}`,
          },
        })

        return {
          ...item,
          tokenId: item.tokenId.toNumber(),
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
          senderPublicKey: meta.data.senderPublicKey,
        }
      })
    )

    // only show items you've received
    // address returned by metamask and address returned by contract have slightly different casing
    state.value.sentItems = items.filter(
      ({ sender }) => res.address.toLowerCase() === sender.toLowerCase()
    )
  } catch (e) {
    console.error('failed to initialize;', e)
  } finally {
    state.value.loading = false
  }
}

ethUtils.registerAccountChangeHandler(() => loadItems())

onMounted(() => loadItems())
</script>

<style scoped></style>
