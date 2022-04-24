<template>
  <div class="flex justify-center gap-4 mb-4">
    <form @submit.prevent="handleSubmit">
      <div class="grid gap-4" style="width: 500px">
        <Input
          v-model="state.formValues.name"
          name="name"
          placeholder="Item Name"
          :disabled="state.disabled"
          autofocus
        />
        <Input
          v-model="state.formValues.recipient"
          name="recipient"
          placeholder="Recipient Address"
          :disabled="state.disabled"
        />
        <Textarea
          v-model="state.formValues.description"
          name="description"
          placeholder="Description"
          :disabled="state.disabled"
          class="h-20"
        />
        <FileInput @input="handleSelectAirdropFile($event)"
          >Select File</FileInput
        >
        <Label v-if="state.formValues.file">{{
          state.formValues.file.name
        }}</Label>

        <Checkbox
          @click="state.showEncryptionMenu = !state.showEncryptionMenu"
          :checked="state.showEncryptionMenu"
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

  readyToSubmit: boolean
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

  readyToSubmit: computed(() => isReadyToSubmit()),
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
    // convert file to base64
    let base64File = (await fileUtils.fileToBase64(
      state.value.formValues.file
    )) as string

    const isEncrypted = state.value.showEncryptionMenu

    if (isEncrypted) {
      if (!state.value.senderKey || !state.value.recipientKey) {
        throw new Error('failed to encypt content; encryption keys not set')
      }

      // format encryption items for openpgp
      const message = await openpgp.createMessage({ text: base64File })

      // encrypt with keypair
      base64File = (await openpgp.encrypt({
        message,
        encryptionKeys: state.value.recipientKey,
        signingKeys: state.value.senderKey,
      })) as string
    }

    // upload to ipfs with metadata
    const uploadedFile = await uploadFile(base64File, {
      name: state.value.formValues.name,
      description: state.value.formValues.description,
      isEncrypted,
      senderPublicKey: state.value.senderKey?.armor(),
    })

    // really you only have to created the token with the hash
    // setting the tokenURI as the full url would break the app if infura went down
    const uploadedFileUrl = `https://ipfs.infura.io/ipfs/${uploadedFile.Hash}`

    const { contract: airdropContract } =
      await ethUtils.establishConnectionAndGetAirdropContract()

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
