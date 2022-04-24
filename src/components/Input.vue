<template>
  <input
    ref="input"
    class="border-2 border-pink-500 rounded p-1"
    :value="modelValue"
    @input="handleChange($event)"
    :disabled="disabled"
  />
</template>

<script setup lang="ts">
import { onMounted, Ref, ref } from 'vue'

const props = defineProps<{
  modelValue: string
  disabled?: boolean
  autofocus?: boolean
}>()

const emits = defineEmits<{
  (e: 'update:modelValue', value: string | number): void
}>()

const handleChange = (e: Event) =>
  emits('update:modelValue', (e.target as HTMLInputElement).value)

const input: Ref<HTMLInputElement | null> = ref(null)

onMounted(() => {
  if (props.autofocus) {
    setTimeout(() => {
      if (input.value) {
        input.value.focus()
      }
    }, 10)
  }
})
</script>

<style scoped></style>
