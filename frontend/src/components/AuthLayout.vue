<!-- src/components/auth/AuthLayout.vue -->
<template lang="pug">
section.auth-page
  .auth-shell
    .card.card-md
      .auth-header
        .logo-mark {{ logoText }}
        h1.auth-title {{ title }}
        p.auth-subtitle {{ subtitle }}

      // 메인 콘텐츠(폼 등)
      main.auth-body
        slot

      .auth-footer
        span {{ footerText }}
        router-link.auth-link(:to="footerLinkTo")
          | {{ footerLinkLabel }}
</template>

<script setup>
const props = defineProps({
  logoText: {
    type: String,
    default: "X",
  },
  title: {
    type: String,
    required: true,
  },
  subtitle: {
    type: String,
    default: "",
  },
  footerText: {
    type: String,
    default: "",
  },
  footerLinkTo: {
    type: String,
    default: "/login",
  },
  footerLinkLabel: {
    type: String,
    default: "",
  },
});
</script>