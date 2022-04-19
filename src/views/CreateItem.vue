<template>
  <div class="flex justify-center gap-4 mb-4">
    <form @submit.prevent="handleSubmit">
      <div
        v-if="state.formView === ITEM_DETAILS"
        class="grid gap-4"
        style="width: 500px"
      >
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
            'flex gap-x-2 items-center justify-between h-6',
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
            class="font-bold text-pink-500 cursor-pointer"
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
        <div class="flex justify-between gap-4 w-full">
          <button
            type="button"
            @click="state.formView = ITEM_DETAILS"
            class="font-bold rounded px-2 text-pink-500 cursor-pointer"
          >
            Back
          </button>
          <button
            type="button"
            :disabled="Boolean(state.generatedKeypairData)"
            class="font-bold rounded p-1 px-2 bg-pink-500 text-white cursor-pointer hover:bg-white border-2 border-pink-500 hover:text-pink-500"
            @click="state.showGenerateKeyInputs = true"
          >
            Generate Keypair
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

        <div class="flex gap-x-2 items-center justify-between">
          <div
            class="flex gap-x-2 items-center"
            @click="
              state.formValues.savePublicKeys = !state.formValues.savePublicKeys
            "
          >
            <!-- <input
              type="checkbox"
              :checked="state.formValues.savePublicKeys"
              :disabled="state.disabled"
              class="cursor-pointer"
            />

            <span
              class="text-base leading-3 tracking-wide font-bold"
              :class="[state.disabled ? 'text-gray-300' : 'text-pink-500']"
            >
              Save Public Keys to the cloud
            </span> -->
          </div>
          <button
            v-if="Boolean(state.generatedKeypairData)"
            type="button"
            class="font-bold rounded p-1 px-2 bg-pink-500 text-white cursor-pointer hover:bg-white border-2 border-pink-500 hover:text-pink-500"
            @click="handleDownloadKeypair()"
          >
            Download Generated Keypair
          </button>
          <a ref="downloadKeypairAnchor" class="hidden" />
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
  <Modal
    v-if="state.showGenerateKeyInputs"
    @close="state.showGenerateKeyInputs = false"
  >
    <div style="width: 300px">
      <h2 class="flex flex-start font-bold pb-2">Enter key data</h2>
      <form @submit.prevent="handleGenerateKeypair()" class="grid gap-2">
        <input
          v-model="state.formValues.newKeyName"
          name="keyName"
          placeholder="Key Name"
          class="border-2 border-pink-500 rounded p-1"
        />
        <input
          v-model="state.formValues.newKeyPassphrase"
          name="keyPassphrase"
          placeholder="Passphrase"
          type="password"
          class="border-2 border-pink-500 rounded p-1"
        />
        <div class="flex flex-end">
          <button
            type="submit"
            :disabled="!state.readyToGenerateKeypair"
            :class="[
              'font-bold rounded p-1 w-full',
              [
                state.readyToGenerateKeypair
                  ? 'bg-pink-500 text-white cursor-pointer hover:bg-white hover:border-2 hover:border-pink-500 hover:text-pink-500'
                  : 'border-2 border-gray-400 text-gray-400 cursor-not-allowed',
              ],
            ]"
          >
            Submit
          </button>
        </div>
      </form>
    </div>
  </Modal>
</template>

<script setup lang="ts">
import { ethers } from 'ethers'
import { computed, ref, Ref } from 'vue'
import { useRouter } from 'vue-router'
import * as openpgp from 'openpgp'
import ProgressBar from '@/components/ProgressBar.vue'
import { Buffer } from 'buffer/'
import { establishConnectionAndGetAirdropContract } from '@/utils'
import Modal from '@/components/Modal.vue'

const IPFS_ENDPOINT = import.meta.env.VITE_APP_IPFS_BASE_URL

const ITEM_DETAILS = 'ITEM_DETAILS'
const ENCRYPTION_DETAILS = 'ENCRYPTION_DETAILS'

interface State {
  loading: boolean
  disabled: boolean
  formValues: {
    name: string
    recipient: string
    description: string
    file?: File

    enableEncryption: boolean
    senderPrivateKey: string
    recipientPublicKey: string
    savePublicKeys: boolean

    newKeyName: string
    newKeyPassphrase: string

    enableNotifications: boolean
  }

  showGenerateKeyInputs: boolean
  generatedKeypairData?: openpgp.SerializedKeyPair<string> & {
    revocationCertificate: string
  }

  formView: string
  readyToSubmit: boolean
  readyToGenerateKeypair: boolean
}

const state: Ref<State> = ref({
  loading: false,
  disabled: false,
  formValues: {
    name: '',
    recipient: '',
    description: '',

    enableEncryption: false,
    senderPrivateKey: '',
    recipientPublicKey: '',
    savePublicKeys: false,

    newKeyName: '',
    newKeyPassphrase: '',

    enableNotifications: false,
  },

  showGenerateKeyInputs: false,

  formView: ITEM_DETAILS,

  readyToSubmit: computed(() => {
    const baseFormValuesAreComplete = Boolean(
      state.value.formValues.name.length &&
        ethers.utils.isAddress(state.value.formValues.recipient) &&
        state.value.formValues.file
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
  readyToGenerateKeypair: computed(() =>
    Boolean(
      state.value.formValues.newKeyName?.length &&
        state.value.formValues.newKeyPassphrase?.length
    )
  ),
})

const downloadKeypairAnchor: Ref<HTMLAnchorElement | null> = ref(null)

const router = useRouter()

const uploadFile = async (content: string, metadata: Object) => {
  try {
    const url = new URL('/api/v0/add?stream-channels=true', IPFS_ENDPOINT) // is the query necessary
    const formData = new FormData()

    // specify file ext in metadata?
    const data = {
      file: content,
      ...metadata,
    }
    formData.append('file', JSON.stringify(data))

    const request = await fetch(url.toString(), {
      method: 'POST',
      body: formData,
    })
    return await request.json()
  } catch (e) {
    console.error('failed to upload file to ipfs;', e)
  }
}

const fileToBase64 = async (file: any) =>
  new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () => resolve(reader.result)
    reader.onerror = (error) => reject(error)
  })

const handleDownloadKeypair = async () => {
  if (!state.value.generatedKeypairData || !downloadKeypairAnchor.value) {
    return
  }

  const keyDataString = Object.values(state.value.generatedKeypairData).join(
    '\n\n'
  )

  const buffer = Buffer.from(keyDataString)
  const base64 = buffer.toString('base64')

  downloadKeypairAnchor.value.href =
    'data:application/octet-stream;base64,' + base64

  downloadKeypairAnchor.value.download = `${state.value.formValues.newKeyName}.txt`
  downloadKeypairAnchor.value.click()
}

const handleSelectFile = (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = (target.files as FileList)[0]
  state.value.formValues.file = file
}

const handleGenerateKeypair = async () => {
  state.value.loading = true

  try {
    const keyData = await openpgp.generateKey({
      type: 'ecc',
      curve: 'curve25519',
      userIDs: [{ name: state.value.formValues.newKeyName }], // TODO-- add key name input -> profile stored in aws will have address, key username and public key -> sign username / key with eth account?
      passphrase: state.value.formValues.newKeyPassphrase, // TODO-- add passphrase input
      format: 'armored',
    })

    state.value.generatedKeypairData = keyData
    state.value.formValues.senderPrivateKey = keyData.privateKey
    state.value.showGenerateKeyInputs = false
  } catch (e) {
    console.error('failed to generate keypair;', e)
  } finally {
    state.value.loading = false
  }
}

const handleSubmit = async () => {
  state.value.loading = true

  // TODO-- add text above loader indicating what is happening
  try {
    // convert file to base64
    let base64File = (await fileToBase64(state.value.formValues.file)) as string

    const isEncrypted = state.value.formValues.enableEncryption

    if (isEncrypted) {
      // format encryption items for openpgp
      const message = await openpgp.createMessage({ text: base64File })
      const publicKey = await openpgp.readKey({
        armoredKey: state.value.formValues.recipientPublicKey,
      })
      const privateKey = await openpgp.decryptKey({
        privateKey: await openpgp.readPrivateKey({
          armoredKey: state.value.formValues.senderPrivateKey,
        }),
        passphrase: state.value.formValues.newKeyPassphrase, // FIXME--
      })

      // encrypt with keypair
      base64File = (await openpgp.encrypt({
        message,
        encryptionKeys: publicKey,
        signingKeys: privateKey,
      })) as string
    }

    // upload to ipfs with metadata
    const uploadedFile = await uploadFile(base64File, {
      name: state.value.formValues.name,
      description: state.value.formValues.description,
      isEncrypted,
    })

    // really you only have to created the token with the hash
    // setting the tokenURI as the full url would break the app if infura went down
    const uploadedFileUrl = `https://ipfs.infura.io/ipfs/${uploadedFile.Hash}`

    const { contract: airdropContract } =
      await establishConnectionAndGetAirdropContract()

    // call create token method
    const transaction = await airdropContract.createToken(
      uploadedFileUrl,
      state.value.formValues.recipient
    )
    await transaction.wait()

    // TODO-- show success popup

    // redirect to home
    router.replace('/')
  } catch (e) {
    state.value.loading = false

    console.error('failed to create token;', e)
  }
}
</script>

<style scoped></style>
