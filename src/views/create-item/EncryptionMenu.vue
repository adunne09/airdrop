<template>
  <div class="grid gap-4 border-y border-gray-400 py-2">
    <div class="grid grid-cols-2 gap-4">
      <FileInput @input="handleUploadSenderKeyfile($event)">
        Upload Keyfile
      </FileInput>
      <Button kind="secondary" @click="state.showGenerateKeyMenu = true">
        Generate Key
      </Button>
    </div>
    <Label v-if="state.encryptionValues.senderKeyfile">{{
      state.encryptionValues.senderKeyfile.name
    }}</Label>
    <FileInput @input="handleUploadRecipientKeyfile($event)">
      Upload Recipient Public Key
    </FileInput>
    <Label v-if="state.encryptionValues.recipientKeyfile">{{
      state.encryptionValues.recipientKeyfile.name
    }}</Label>
  </div>

  <Modal
    v-if="state.showEnterPassphrase"
    @close="state.showEnterPassphrase = false"
  >
    <div style="width: 300px">
      <h2 class="font-bold pb-2">Enter key passphrase</h2>
      <form @submit.prevent="handleReadSenderKeyfile()" class="grid gap-4">
        <Input
          v-model="state.encryptionValues.senderPrivateKeyPassphrase"
          name="key-passphrase"
          placeholder="Passphrase"
          type="password"
          autofocus
        />

        <span
          v-if="state.encryptionValues.error.length"
          class="font-bold text-red-500"
          >{{ state.encryptionValues.error }}</span
        >

        <Button
          type="submit"
          kind="primary"
          :disabled="!state.encryptionValues.senderPrivateKeyPassphrase.length"
        >
          Submit
        </Button>
      </form>
    </div>
  </Modal>

  <Modal
    v-else-if="state.showGenerateKeyMenu"
    @close="state.showGenerateKeyMenu = false"
  >
    <div style="width: 300px">
      <h2 class="font-bold pb-2">Enter key details</h2>
      <form @submit.prevent="handleGenerateSenderKeyfile()" class="grid gap-4">
        <Input
          v-model="state.encryptionValues.senderNewKeyName"
          name="key-name"
          placeholder="Key Name"
          autofocus
        />
        <Input
          v-model="state.encryptionValues.senderPrivateKeyPassphrase"
          name="key-passphrase"
          placeholder="Passphrase"
          type="password"
        />

        <a ref="downloadKeyfileAnchor" class="hidden" />
        <Button
          type="submit"
          kind="primary"
          :disabled="
            !state.encryptionValues.senderPrivateKeyPassphrase.length ||
            !state.encryptionValues.senderNewKeyName.length
          "
        >
          Submit
        </Button>
      </form>
    </div>
  </Modal>
</template>

<script setup lang="ts">
import Modal from '@/components/Modal.vue'
import Button from '@/components/Button.vue'
import FileInput from '@/components/FileInput.vue'
import Label from '@/components/Label.vue'
import Input from '@/components/Input.vue'
import * as openpgp from 'openpgp'
import { Ref, ref } from 'vue'
import { computed } from '@vue/reactivity'
import { fileUtils } from '../../utils'
import { Buffer } from 'buffer/'

interface State {
  encryptionValues: {
    senderPrivateKeyPassphrase: string
    senderPrivateKey: openpgp.PrivateKey | null // must successfully read key with the passphrase
    senderPublicKey: string
    senderKeyfile?: File

    senderNewKeyName: string

    recipientPublicKey: openpgp.Key | null // must successfully read key
    recipientKeyfile?: File

    error: string
  }

  showGenerateKeyMenu: boolean
  showEnterPassphrase: boolean

  readyToSubmit: boolean
}

const state: Ref<State> = ref({
  encryptionValues: {
    senderPrivateKey: null,
    senderPublicKey: '',
    senderPrivateKeyPassphrase: '',

    senderNewKeyName: '',

    recipientPublicKey: null,

    error: '',
  },

  showGenerateKeyMenu: false,
  showEnterPassphrase: false,

  readyToSubmit: computed(() => isReadyToSubmit()),
})

const isReadyToSubmit = (): boolean =>
  Boolean(
    state.value.encryptionValues.senderPrivateKey &&
      state.value.encryptionValues.recipientPublicKey
  )

const emits = defineEmits<{
  (e: 'update:senderKey', value: openpgp.PrivateKey): void
  (e: 'update:recipientKey', value: openpgp.Key): void
}>()

const handleUploadSenderKeyfile = (e: Event) => {
  const target = e.target as HTMLInputElement
  const file = (target.files as FileList)[0]

  state.value.encryptionValues.senderKeyfile = file

  state.value.showEnterPassphrase = true
}

const handleReadSenderKeyfile = async () => {
  if (!state.value.encryptionValues.senderKeyfile) {
    return
  }

  try {
    const privateKeyStartIdentifier = '-----BEGIN PGP PRIVATE KEY BLOCK-----'
    const privateKeyEndIdentifier = '-----END PGP PRIVATE KEY BLOCK-----'

    const [privateKeyRaw, err] = await fileUtils.parseStringFromFile(
      state.value.encryptionValues.senderKeyfile,
      privateKeyStartIdentifier,
      privateKeyEndIdentifier
    )
    if (err) {
      throw new Error(err.message)
    }

    const senderPrivateKey = await openpgp.decryptKey({
      privateKey: await openpgp.readPrivateKey({ armoredKey: privateKeyRaw }),
      passphrase: state.value.encryptionValues.senderPrivateKeyPassphrase,
    })
    state.value.encryptionValues.senderPrivateKey = senderPrivateKey

    emits('update:senderKey', senderPrivateKey)

    state.value.showEnterPassphrase = false
    state.value.encryptionValues.error = ''
  } catch (e) {
    console.error('failed to read sender keyfile;', e)

    if ((e as any).message?.indexOf('Incorrect key passphrase') !== -1) {
      console.log('herere')
      state.value.encryptionValues.error = 'Incorrect key passphrase'
    }
  }
}

const downloadKeyfileAnchor: Ref<HTMLAnchorElement | null> = ref(null)

const handleGenerateSenderKeyfile = async () => {
  try {
    const keyData = await openpgp.generateKey({
      type: 'ecc',
      curve: 'curve25519',
      userIDs: [{ name: state.value.encryptionValues.senderNewKeyName }],
      passphrase: state.value.encryptionValues.senderPrivateKeyPassphrase,
      format: 'armored',
    })

    const senderPrivateKey = await openpgp.decryptKey({
      privateKey: await openpgp.readPrivateKey({
        armoredKey: keyData.privateKey,
      }),
      passphrase: state.value.encryptionValues.senderPrivateKeyPassphrase,
    })
    state.value.encryptionValues.senderPrivateKey = senderPrivateKey

    const keyfileName = `${state.value.encryptionValues.senderNewKeyName}.txt`
    state.value.encryptionValues.senderKeyfile = {
      name: keyfileName,
    } // contruct a new Blob

    emits('update:senderKey', senderPrivateKey)
    state.value.showGenerateKeyMenu = false

    if (!downloadKeyfileAnchor.value) {
      console.error(
        'failed to download generated key file; something went wrong'
      )
      return
    }

    const keyDataString = Object.values(keyData).join('\n\n')

    const buffer = Buffer.from(keyDataString)
    const base64 = buffer.toString('base64')

    downloadKeyfileAnchor.value.href =
      'data:application/octet-stream;base64,' + base64
    downloadKeyfileAnchor.value.download = keyfileName
    downloadKeyfileAnchor.value.click()
  } catch (e) {
    console.error('failed to generate sender keyfile;', e)
  }
}

const handleUploadRecipientKeyfile = async (e: Event) => {
  try {
    const target = e.target as HTMLInputElement
    const file = (target.files as FileList)[0]

    const publicKeyStartIdentifier = '-----BEGIN PGP PUBLIC KEY BLOCK-----'
    const publicKeyEndIdentifier = '-----END PGP PUBLIC KEY BLOCK-----'

    const [publicKeyRaw, err] = await fileUtils.parseStringFromFile(
      file,
      publicKeyStartIdentifier,
      publicKeyEndIdentifier
    )
    if (err) {
      throw new Error(err.message)
    }

    const recipientPublicKey = await openpgp.readKey({
      armoredKey: publicKeyRaw,
    })

    state.value.encryptionValues.recipientPublicKey = recipientPublicKey
    state.value.encryptionValues.recipientKeyfile = file

    emits('update:recipientKey', recipientPublicKey)
  } catch (e) {
    console.error('failed to upload recipient public key;', e)
  }
}
</script>

<style scoped></style>
