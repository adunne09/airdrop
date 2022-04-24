<template>
  <div
    v-if="isVisible"
    class="fixed bottom-10 flex inset-x-0 -translate-y-1/2 z-50"
  >
    <div
      :class="[
        'text-white w-60 m-auto px-4 py-2 rounded-xl text-sm flex justify-between items-center transition-all duration-1000 ease-in-out',
        { 'bg-green-500': type === 'success' },
        { 'bg-red-500': type === 'error' },
      ]"
    >
      {{ message }}
      <button
        @click="isVisible = false"
        class="underline cursor-pointer"
        type="button"
      >
        Close
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'

const props = withDefaults(
  defineProps<{
    type: 'success' | 'error'
    message: string
    expiresAt?: number
  }>(),
  {
    expiresAt: 3000,
  }
)

const isVisible = ref(false)

onMounted(() => {
  isVisible.value = true

  if (props.expiresAt) {
    setTimeout(() => {
      if (isVisible.value) {
        isVisible.value = false
      }
    }, props.expiresAt)
  }
})
</script>

<style scoped></style>
