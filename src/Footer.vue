<template>
  <div
    class="w-full fixed bottom-0 border-t-2 border-pink-500 flex gap-4 justify-center bg-white"
  >
    <Label>{{ version }}</Label>
    <Label kind="secondary">2022 {{ author }}</Label>
  </div>
</template>

<script setup lang="ts">
import Label from '@/components/Label.vue'

const version = import.meta.env.VITE_APP_VERSION
const author = import.meta.env.VITE_APP_AUTHOR
</script>

<style scoped></style>
