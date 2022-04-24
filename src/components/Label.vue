<template>
  <label
    :for="labelFor"
    class="text-pink-500 ease-out text-sm leading-2 tracking-widest font-semibold uppercase"
  >
    <slot />
  </label>
</template>

<script setup lang="ts">
defineProps<{
  disabled?: boolean
  labelFor?: string
}>()
</script>

<style scoped></style>
