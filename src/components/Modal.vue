<template>
  <div class="fixed overflow-y-auto inset-0">
    <div
      class="fixed inset-0 transition-opacity cursor-pointer bg-gray-100 bg-opacity-70 z-10"
      @click="$emit('close')"
    />

    <div class="flex items-center justify-center min-h-screen">
      <div class="relative z-20 p-4">
        <div class="p-8 border-2 rounded border-pink-500 bg-white">
          <slot />
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, onUnmounted } from '@vue/runtime-core'

defineEmits(['close'])

const disableBackgroundScrolling = () =>
  document.body.classList.add('overflow-y-hidden')

const enableBackgroundScrolling = () =>
  document.body.classList.remove('overflow-y-hidden')

onMounted(() => disableBackgroundScrolling())
onUnmounted(() => enableBackgroundScrolling())
</script>
