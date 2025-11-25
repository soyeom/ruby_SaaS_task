<template lang="pug">
div.app-root
  main.app-main
    router-view
</template>

<script setup>
</script>

<style scoped>
.app-root {
  min-height: 100vh;
  background: #f7f7f5;
}

.app-main {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}
</style>
