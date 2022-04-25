<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else>
    <h2 v-if="!state.sentItems.length">You haven't sent any items.</h2>
    <div
      v-else
      class="grid gap-4 overflow-y-auto"
      style="grid-template-columns: repeat(3, 300px)"
    >
      <div
        class="border shadow rounded-xl overflow-hidden"
        v-for="(item, index) in state.sentItems"
        :key="index"
      >
        <div class="p-4">
          <p class="text-2xl font-semibold h-16">{{ item.name }}</p>
          <div class="h-16 overflow-hidden">
            <p class="text-gray-400">{{ item.description }}</p>
            <p class="text-gray-400">
              Recipient: {{ `${item.recipient.slice(0, 10)}...` }}
            </p>
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
import { ethUtils } from '../utils'

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
        const meta = await axios.get(tokenUri)

        return {
          ...item,
          tokenId: item.tokenId.toNumber(),
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
        }
      })
    )

    // only show items you've received
    // address returned by metamask and address returned by contract have slightly different casing
    state.value.sentItems = items.filter(
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
</script>

<style scoped></style>
