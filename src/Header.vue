<template>
  <header class="w-full flex justify-center my-8">
    <div class="flex-1 mb-7 border-b-2 border-pink-500" />
    <div class="flex-1">
      <div class="flex justify-center items-center gap-4">
        <PolygonIcon />
        <router-link to="/" class="text-4xl font-bold hover:text-pink-500">
          Airdrop Bazaar
        </router-link>
      </div>
      <div class="flex justify-center">
        <Status :status="state.status">{{ state.address }}</Status>
      </div>
      <div
        class="grid items-center border-2 border-pink-500 rounded-lg"
        style="grid-template-columns: repeat(4, 200px)"
      >
        <div class="border-r border-pink-500">
          <HeaderLink to="/" title="Home" />
        </div>
        <HeaderLink to="/create-item" title="Create Item" />
        <div class="border-x border-pink-500">
          <HeaderLink to="/received-items" title="Received Items" />
        </div>
        <HeaderLink to="/sent-items" title="Sent Items" />
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
import { ethUtils } from './utils'
import PolygonIcon from '@/assets/polygon-logo.svg?component'

interface State {
  status: string
  address?: string
}

const state: Ref<State> = ref({
  status: 'pending',
})

ethUtils.registerAccountChangeHandler((accounts: string[]) => {
  if (!accounts.length) {
    throw new Error('must select an account')
  }

  state.value.address = accounts[0]
})

onMounted(async () => {
  try {
    const { address } =
      await ethUtils.establishConnectionAndGetAirdropContract()

    state.value.address = address
    state.value.status = 'success'
  } catch (e) {
    state.value.status = 'error'

    console.error('failed to establish ethereum connection;', e)
  }
})
</script>

<style scoped></style>
