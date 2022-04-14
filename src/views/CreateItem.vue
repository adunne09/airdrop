<template>
  <div class="flex justify-center gap-4">
    <form @submit.prevent="">
      <div v-if="state.formView === ITEM_DETAILS" class="grid gap-4">
        <input
          v-model="state.formValues.name"
          name="name"
          placeholder="Item Name"
          :disabled="state.disabled"
          class="border-2 border-pink-500 rounded p-1"
        />
        <input
          v-model="state.formValues.recipient"
          name="recipient"
          placeholder="Recipient Address"
          :disabled="state.disabled"
          class="border-2 border-pink-500 rounded p-1"
        />
        <textarea
          v-model="state.formValues.description"
          name="description"
          placeholder="Description"
          :disabled="state.disabled"
          class="border-2 border-pink-500 rounded p-1 resize-none h-20"
        />
        <input
          type="file"
          name="file"
          @input="handleSelectFile($event)"
          class="p-1"
        />
        <div
          :class="[
            'flex gap-x-2 items-center justify-between',
            state.disabled ? 'cursor-not-allowed' : 'cursor-pointer',
          ]"
        >
          <div
            class="flex gap-x-2"
            @click="
              state.formValues.enableEncryption =
                !state.formValues.enableEncryption
            "
          >
            <input
              type="checkbox"
              :checked="state.formValues.enableEncryption"
              :disabled="state.disabled"
              class="cursor-pointer"
            />

            <span
              class="text-base leading-3 tracking-wide font-bold"
              :class="[state.disabled ? 'text-gray-300' : 'text-pink-500']"
            >
              Enable Encryption
            </span>
          </div>

          <button
            v-if="state.formValues.enableEncryption"
            type="button"
            @click="state.formView = ENCRYPTION_DETAILS"
            class="font-bold rounded px-2 text-pink-500 cursor-pointer"
          >
            Next
          </button>
        </div>
      </div>
      <div
        v-else-if="state.formView === ENCRYPTION_DETAILS"
        class="grid gap-4"
        style="width: 600px"
      >
        <div class="flex gap-4 w-full">
          <button
            type="button"
            @click="state.formView = ITEM_DETAILS"
            class="font-bold rounded px-2 text-pink-500 cursor-pointer"
          >
            Back
          </button>
          <button
            type="button"
            class="w-full font-bold rounded p-1 px-2 bg-pink-500 text-white cursor-pointer hover:bg-white border-2 border-pink-500 hover:text-pink-500"
            @click="handleGenerateKeypair()"
          >
            Generate Keypair
          </button>
          <button
            type="button"
            class="w-full font-bold rounded p-1 px-2 text-pink-500 cursor-pointer hover:bg-pink-500 border-2 border-pink-500 hover:text-white"
          >
            Enter keypair
          </button>
          <!-- add upload keyfile functionality -->
        </div>

        <div class="relative flex justify-center">
          <ProgressBar
            v-if="state.loading"
            :loading="state.loading"
            class="absolute top-60 w-4/5"
          />

          <div :class="['grid gap-4 w-full', { 'opacity-30': state.loading }]">
            <textarea
              v-model="state.formValues.senderPrivateKey"
              name="private-key"
              placeholder="Your private key"
              :disabled="state.disabled"
              class="border-2 border-pink-500 rounded p-1 resize-none"
              style="height: 300px"
            />
            <textarea
              v-model="state.formValues.recipientPublicKey"
              name="public-key"
              placeholder="The recipient's public key"
              :disabled="state.disabled"
              class="border-2 border-pink-500 rounded p-1 resize-none"
              style="height: 300px"
            />
          </div>
        </div>

        <div
          class="flex gap-x-2"
          @click="
            state.formValues.savePublicKeys = !state.formValues.savePublicKeys
          "
        >
          <input
            type="checkbox"
            :checked="state.formValues.savePublicKeys"
            :disabled="state.disabled"
            class="cursor-pointer"
          />

          <span
            class="text-base leading-3 tracking-wide font-bold"
            :class="[state.disabled ? 'text-gray-300' : 'text-pink-500']"
          >
            Save Public Keys
          </span>
        </div>
        <!-- add disclaimer re private keys - not connected to funds, only used for encryption, private keys do not leave the browser -->
      </div>
      <button
        type="submit"
        :disabled="!state.readyToSubmit"
        :class="[
          'font-bold rounded p-1 w-full mt-4',
          [
            state.readyToSubmit
              ? 'bg-pink-500 text-white cursor-pointer hover:bg-white hover:border-2 hover:border-pink-500 hover:text-pink-500'
              : 'border-2 border-gray-400 text-gray-400 cursor-not-allowed',
          ],
        ]"
      >
        Submit
      </button>
    </form>
  </div>
</template>

<script setup lang="ts">
import { ethers } from 'ethers'
// import { create as ipfsHttpClient } from 'ipfs-http-client'
import { computed, ref, Ref } from 'vue'
import { useRouter } from 'vue-router'
import * as openpgp from 'openpgp'
import ProgressBar from '@/components/ProgressBar.vue'

import Airdrop from '../../out/Airdrop.sol/Airdrop.json'

const airdropContractAddress = import.meta.env.VITE_APP_AIRDROP_CONTRACT_ADDRESS
const ipfsEndpoint = import.meta.env.VITE_APP_IPFS_API_ENDPOINT

// const ipfsClient = ipfsHttpClient({ url: ipfsEndpoint })

const ITEM_DETAILS = 'ITEM_DETAILS'
const ENCRYPTION_DETAILS = 'ENCRYPTION_DETAILS'

interface State {
  loading: boolean
  disabled: boolean
  formValues: {
    name: string
    recipient: string
    description: string
    fileUrl: string

    enableEncryption: boolean
    senderPrivateKey: string
    recipientPublicKey: string
    savePublicKeys: boolean

    enableNotifications: boolean
  }
  formView: string
  readyToSubmit: boolean
}

const state: Ref<State> = ref({
  loading: false,
  disabled: false,
  formValues: {
    name: '',
    recipient: '',
    description: '',
    fileUrl: '',

    enableEncryption: false,
    senderPrivateKey: '',
    recipientPublicKey: '',
    savePublicKeys: false,

    enableNotifications: false,
  },
  formView: ITEM_DETAILS,
  readyToSubmit: computed(() => {
    const baseFormValuesAreComplete = Boolean(
      state.value.formValues.name.length &&
        ethers.utils.isAddress(state.value.formValues.recipient) &&
        state.value.formValues.fileUrl.length
    )

    if (state.value.formValues.enableEncryption) {
      return (
        baseFormValuesAreComplete &&
        Boolean(
          state.value.formValues.senderPrivateKey.length &&
            state.value.formValues.recipientPublicKey.length
        )
      )
    }

    return baseFormValuesAreComplete
  }),
})

const handleSelectFile = async (e: Event) => {
  state.value.loading = true

  try {
    const target = e.target as any
    const file = target.files[0]

    console.log('file selected')
  } catch (e) {
    console.error('failed to select file;', e)
  } finally {
    state.value.loading = false
  }
}

const handleGenerateKeypair = async () => {
  state.value.loading = true

  setTimeout(() => {
    state.value.loading = false
  }, 5000)
}

const handleSubmit = async () => {}
</script>

<style scoped></style>
