<template>
  <label
    :for="labelFor"
    :class="[
      'ease-out text-sm leading-2 tracking-widest font-semibold uppercase',
      { 'text-pink-500': kind === 'primary' },
      { 'text-purple-600': kind === 'secondary' },
    ]"
  >
    <slot />
  </label>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    disabled?: boolean
    labelFor?: string
    kind?: 'primary' | 'secondary'
  }>(),
  {
    kind: 'primary',
  }
)
</script>

<style scoped></style>
