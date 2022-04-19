<template>
  <header class="w-full flex justify-center my-8">
    <div class="flex-1 mb-7 border-b-2 border-pink-500" />
    <div class="flex-1">
      <router-link to="/" class="text-4xl font-bold hover:text-pink-500">
        Airdrop Bazaar
      </router-link>
      <div class="flex justify-center">
        <Status :status="state.status">{{ state.address }}</Status>
      </div>
      <div
        class="flex justify-around m2-4 items-center border-2 border-pink-500 rounded-lg"
      >
        <HeaderLink to="/create-item" title="Create Item" />
        <div class="border-l border-pink-500 h-4 w-1" />
        <HeaderLink to="/unclaimed-items" title="Unclaimed Items" />
        <div class="border-r border-pink-500 h-4 w-1" />
        <HeaderLink to="/created-items" title="Created Items" />
      </div>
    </div>
    <div class="flex-1 mb-7 border-b-2 border-pink-500" />
  </header>
</template>

<script setup lang="ts">
import HeaderLink from '@/components/HeaderLink.vue'
import Status from '@/components/Status.vue'
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import {
  establishConnectionAndGetAirdropContract,
  registerAccountChangeHandler,
} from '@/utils'

interface State {
  status: string
  address?: string
}

const state: Ref<State> = ref({
  status: 'pending',
})

registerAccountChangeHandler((accounts: string[]) => {
  if (!accounts.length) {
    throw new Error('must select an account')
  }

  state.value.address = accounts[0]
})

onMounted(async () => {
  try {
    const { address } = await establishConnectionAndGetAirdropContract()

    state.value.address = address
    state.value.status = 'success'
  } catch (e) {
    state.value.status = 'error'

    console.error('failed to establish ethereum connection;', e)
  }
})
</script>

<style scoped></style>
