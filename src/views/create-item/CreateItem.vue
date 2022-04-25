<template>
  <div class="flex justify-center gap-4 mb-4">
    <form @submit.prevent="handleSubmit">
      <div
        style="width: 500px"
        :class="['grid gap-4', { 'opacity-30': state.loading }]"
      >
        <Input
          v-model="state.formValues.name"
          name="name"
          placeholder="Item Name"
          :disabled="state.formIsDisabled"
          autofocus
        />
        <Input
          v-model="state.formValues.recipient"
          name="recipient"
          placeholder="Recipient Address"
          :disabled="state.formIsDisabled"
        />
        <Textarea
          v-model="state.formValues.description"
          name="description"
          placeholder="Description"
          :disabled="state.formIsDisabled"
          class="h-20"
        />
        <FileInput
          @input="handleSelectAirdropFile($event)"
          :disabled="state.formIsDisabled"
          >Select File</FileInput
        >
        <Label v-if="state.formValues.file">{{
          state.formValues.file.name
        }}</Label>

        <Checkbox
          @click="state.showEncryptionMenu = !state.showEncryptionMenu"
          :checked="state.showEncryptionMenu"
          :disabled="state.formIsDisabled"
        >
          Enable Encryption
        </Checkbox>
        <EncryptionMenu
          v-if="state.showEncryptionMenu"
          @update:senderKey="state.senderKey = $event"
          @update:recipientKey="state.recipientKey = $event"
        />
        <Button type="submit" kind="primary" :disabled="!state.readyToSubmit"
          >Submit</Button
        >
      </div>
    </form>
  </div>
  <div v-if="state.loading" class="relative flex justify-center">
    <!-- TODO-- y center this -->
    <ProgressBar
      :percentage="state.progress.percentage"
      :text="state.progress.text"
      class="absolute bottom-40 w-4/5"
    />
  </div>
</template>

<script setup lang="ts">
import { ethers } from 'ethers'
import { computed, ref, Ref } from 'vue'
import { useRouter } from 'vue-router'
import * as openpgp from 'openpgp'
import { ethUtils, fileUtils } from '../../utils'
import Button from '@/components/Button.vue'
import Input from '@/components/Input.vue'
import Textarea from '@/components/Textarea.vue'
import FileInput from '@/components/FileInput.vue'
import Checkbox from '@/components/Checkbox.vue'
import Label from '@/components/Label.vue'
import ProgressBar from '@/components/ProgressBar.vue'
import EncryptionMenu from './EncryptionMenu.vue'

const IPFS_ENDPOINT = import.meta.env.VITE_APP_IPFS_BASE_URL

interface State {
  loading: boolean
  disabled: boolean
  formValues: {
    name: string
    recipient: string
    description: string
    file?: File
  }

  showEncryptionMenu: boolean
  senderKey: openpgp.PrivateKey | null
  recipientKey: openpgp.Key | null

  formIsDisabled: boolean
  readyToSubmit: boolean

  progress: {
    text: string
    percentage: number
  }
}

const state: Ref<State> = ref({
  loading: false,
  disabled: false,
  formValues: {
    name: '',
    recipient: '',
    description: '',
  },

  showEncryptionMenu: false,
  senderKey: null,
  recipientKey: null,

  formIsDisabled: computed(() => !formIsReady()),
  readyToSubmit: computed(() => isReadyToSubmit()),

  progress: {
    text: '',
    percentage: 0,
  },
})

const isReadyToSubmit = () => {
  const baseFormValuesAreComplete = Boolean(
    state.value.formValues.name.length &&
      ethers.utils.isAddress(state.value.formValues.recipient) &&
      state.value.formValues.file
  )

  if (state.value.showEncryptionMenu) {
    return (
      baseFormValuesAreComplete &&
      Boolean(state.value.senderKey && state.value.recipientKey)
    )
  }

  return baseFormValuesAreComplete
}

const formIsReady = () => !state.value.disabled && !state.value.loading

const handleSelectAirdropFile = (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = (target.files as FileList)[0]
  state.value.formValues.file = file
}

const router = useRouter()

const uploadFile = async (content: string, metadata: Object) => {
  try {
    const url = new URL('/api/v0/add?stream-channels=true', IPFS_ENDPOINT) // is the query necessary
    const formData = new FormData()

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

const handleSubmit = async () => {
  state.value.loading = true

  // TODO-- add text above loader indicating what is happening
  try {
    const isEncrypted = state.value.showEncryptionMenu

    let currentStep = 0
    const steps = isEncrypted ? 6 : 4

    // convert file to base64
    state.value.progress = {
      text: 'Formatting file for upload',
      percentage: 0,
    }
    let base64File = (await fileUtils.fileToBase64(
      state.value.formValues.file
    )) as string

    if (isEncrypted) {
      if (!state.value.senderKey || !state.value.recipientKey) {
        throw new Error('failed to encypt content; encryption keys not set')
      }

      // format encryption items for openpgp
      state.value.progress = {
        text: 'Formatting file for encryption',
        percentage: (currentStep++ / steps) * 100,
      }
      const message = await openpgp.createMessage({ text: base64File })

      // encrypt with keypair
      state.value.progress = {
        text: 'Encrypting file',
        percentage: (currentStep++ / steps) * 100,
      }
      base64File = (await openpgp.encrypt({
        message,
        encryptionKeys: state.value.recipientKey,
        signingKeys: state.value.senderKey,
      })) as string
    }

    // upload to ipfs with metadata
    state.value.progress = {
      text: 'Uploading to IPFS',
      percentage: (currentStep++ / steps) * 100,
    }
    const uploadedFile = await uploadFile(base64File, {
      name: state.value.formValues.name,
      description: state.value.formValues.description,
      isEncrypted,
      senderPublicKey: state.value.senderKey?.armor(),
    })

    // really you only have to created the token with the hash
    // setting the tokenURI as the full url would break the app if infura went down
    const uploadedFileUrl = `https://ipfs.infura.io/ipfs/${uploadedFile.Hash}`

    state.value.progress = {
      text: 'Connecting to Polygon',
      percentage: (currentStep++ / steps) * 100,
    }
    const { contract: airdropContract } =
      await ethUtils.establishConnectionAndGetAirdropContract()

    // call create token method
    state.value.progress = {
      text: 'Intitiating airdrop transaction',
      percentage: (currentStep++ / steps) * 100,
    }
    const transaction = await airdropContract.createToken(
      uploadedFileUrl,
      state.value.formValues.recipient
    )

    // TODO-- show success popup

    state.value.progress = {
      text: 'Confirming transaction',
      percentage: (currentStep++ / steps) * 100,
    }
    await transaction.wait()

    // redirect to home
    router.replace('/')
  } catch (e) {
    state.value.loading = false

    console.error('failed to create token;', e)
  }
}
</script>

<style scoped></style>
