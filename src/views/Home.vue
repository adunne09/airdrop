<script setup lang="ts">
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { ethers } from 'ethers'
import axios from 'axios'
import Airdrop from '../../out/Airdrop.sol/Airdrop.json'
import detectEthereumProvider from '@metamask/detect-provider'
import ProgressBar from '@/components/ProgressBar.vue'

const airdropContractAddress = import.meta.env.VITE_APP_AIRDROP_CONTRACT_ADDRESS

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
  items: any[]
}

const state: Ref<State> = ref({
  loading: false,
  items: [],
})

onMounted(async () => {
  state.value.loading = true

  try {
    const connection = (await detectEthereumProvider()) as any
    const provider = new ethers.providers.Web3Provider(connection)

    const signer = provider.getSigner()

    const airdropContract = new ethers.Contract(
      airdropContractAddress!,
      Airdrop.abi,
      signer
    )

    const data = await airdropContract.fetchSentItems()

    const items = await Promise.all(
      data.map(async (i: any) => {
        const tokenUri = await airdropContract.tokenURI(i.tokenId)
        const meta = await axios.get(tokenUri)

        return {
          tokenId: i.tokenId.toNumber(),
          sender: i.sender,
          recipient: i.recipient,
          name: meta.data.name,
          description: meta.data.description,
          file: meta.data.file,
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
</script>

<template>
  <ProgressBar v-if="state.loading" :loading="state.loading" class="w-96" />
  <div v-else>
    <h2 v-if="!state.items.length">No Items Found</h2>
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
        <img :src="item.file" alt="nft image" style="max-height: 200px" />
        <div class="p-4">
          <p class="text-2xl font-semibold h-16">{{ item.name }}</p>
          <div class="h-16 overflow-hidden">
            <p class="text-gray-400">{{ item.description }}</p>
          </div>
        </div>
        <div class="p-4 bg-black">
          <div
            class="w-full bg-pink-500 text-white font-bold py-2 px-12 rounded"
          >
            {{ item.claimed ? 'Claimed' : 'Unclaimed' }}
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped></style>