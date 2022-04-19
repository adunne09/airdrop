<template>
  <div class="flex items-center gap-1">
    <div class="flex relative">
      <span
        v-if="status === 'pending'"
        class="animate-ping absolute inline-flex h-2.5 w-2.5 rounded-full opacity-75 -top-0.5 -left-0.5 warning-animation-bg"
      />
      <span
        :class="[
          'w-1.5 h-1.5 rounded-full',
          { 'bg-gray-300': status === 'default' },
          { 'bg-green-600 shadow-success-3': status === 'success' },
          { 'bg-yellow-500 shadow-warning-3': status === 'pending' },
          { 'bg-red-500 shadow-warning-3': status === 'failure' },
        ]"
      />
    </div>
    <span class="text-black text-sm uppercase leading-2 tracking-widest">
      <slot />
    </span>
  </div>
</template>

<script setup lang="ts">
defineProps<{ status: 'default' | 'success' | 'pending' | 'failure' }>()
</script>

<style scoped>
.warning-animation-bg {
  background-color: #fce7ab;
}
</style>
