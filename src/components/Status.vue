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
          { 'bg-success shadow-success-3': status === 'success' },
          { 'bg-warning shadow-warning-3': status === 'pending' },
          { 'bg-error shadow-warning-3': status === 'failure' },
        ]"
      />
    </div>
    <span class="text-black text-sm uppercase leading-2 tracking-widest">
      <slot />
    </span>
  </div>
</template>

<script setup lang="ts">
defineProps<{ status: 'success' | 'pending' | 'failure' }>()
</script>

<style scoped>
.bg-success {
  --tw-bg-opacity: 1;
  background-color: rgba(101, 175, 106, var(--tw-bg-opacity));
}

.bg-warning {
  --tw-bg-opacity: 1;
  background-color: rgba(248, 206, 86, var(--tw-bg-opacity));
}

.bg-warning {
  --tw-bg-opacity: 1;
  background-color: rgba(248, 206, 86, var(--tw-bg-opacity));
}

.warning-animation-bg {
  background-color: #fce7ab;
}
</style>
