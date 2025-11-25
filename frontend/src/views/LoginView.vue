<!-- src/views/LoginView.vue -->
<template lang="pug">
AuthLayout(
  title="タスク管理ツールへようこそ"
  subtitle="ログインしてワークスペースとタスクを管理しましょう。"
  footer-text="アカウントをお持ちでない方は"
  footer-link-to="/signup"
  footer-link-label="サインアップ"
)
  form.auth-form(@submit.prevent="onSubmit")
    .form-group
      label.form-label(for="login_id") ログインID
      input.form-input#login_id(
        type="text"
        v-model="form.login_id"
        placeholder="example_user"
        autocomplete="username"
      )

    .form-group
      label.form-label(for="password") パスワード
      input.form-input#password(
        type="password"
        v-model="form.password"
        placeholder="••••••••"
        autocomplete="current-password"
      )

    p.form-error(v-if="errorMessage") {{ errorMessage }}

    button.primary(type="submit" :disabled="isSubmitting")
      span(v-if="isSubmitting") ログイン中...
      span(v-else) ログイン
</template>

<script setup>
import { reactive, ref } from "vue";
import { useRouter } from "vue-router";
import { login } from "@/api/auth";
import AuthLayout from "@/components/AuthLayout.vue";

const router = useRouter();

const form = reactive({
  login_id: "",
  password: "",
});

const errorMessage = ref("");
const isSubmitting = ref(false);

const onSubmit = async () => {
  errorMessage.value = "";

  if (!form.login_id || !form.password) {
    errorMessage.value = "login_id と password は必須です。";
    return;
  }

  try {
    isSubmitting.value = true;

    const res = await login({
      login_id: form.login_id,
      password: form.password,
    });

    console.log("login success:", res.data);
    router.push("/workspaces");
  } catch (err) {
    const data = err.response?.data;
    errorMessage.value = data?.error || "ログインに失敗しました。";
  } finally {
    isSubmitting.value = false;
  }
};
</script>
