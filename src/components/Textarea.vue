<template>
  <textarea
    class="border-2 border-pink-500 rounded p-1 resize-none"
    :value="modelValue"
    @input="handleChange($event)"
    :disabled="disabled"
  />
</template>

<script setup lang="ts">
defineProps<{
  modelValue: string
  disabled?: boolean
}>()

const emits = defineEmits<{
  (e: 'update:modelValue', value: string | number): void
}>()

const handleChange = (e: Event) =>
  emits('update:modelValue', (e.target as HTMLTextAreaElement).value)
</script>

<style scoped></style>
