<template>
  <label
    :for="id"
    :class="[
      'font-bold py-1 bg-pink-500 text-white rounded border-2 border-pink-500 hover:bg-white hover:text-pink-500',
      { 'cursor-pointer': !disabled },
      { 'cursor-not-allowed': disabled },
    ]"
  >
    <input :id="id" type="file" class="hidden" v-bind="$attrs" />
    <slot />
  </label>
</template>

<script setup lang="ts">
import { v4 } from 'uuid'

defineProps<{
  disabled?: boolean
}>()

const id = v4()
</script>

<style scoped></style>
