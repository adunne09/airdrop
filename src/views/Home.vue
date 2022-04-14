<script setup lang="ts">
import { onMounted } from '@vue/runtime-core'
import { ref, Ref } from 'vue'
import { ethers } from 'ethers'
import axios from 'axios'
import Airdrop from '../../out/Airdrop.sol/Airdrop.json'
import detectEthereumProvider from '@metamask/detect-provider'

const airdropContractAddress = import.meta.env.VITE_APP_AIRDROP_CONTRACT_ADDRESS

interface State {
  loading: boolean
  signer?: ethers.providers.JsonRpcSigner
}

const state: Ref<State> = ref({
  loading: false,
  signer: undefined,
})

onMounted(async () => {
  try {
    const connection = (await detectEthereumProvider()) as any
    const provider = new ethers.providers.Web3Provider(connection)

    state.value.signer = provider.getSigner()
  } catch (e) {
    console.error('failed to initialize signer;', e)
  }
})
</script>

<template>
  <div>hello world</div>
</template>

<style scoped></style>
