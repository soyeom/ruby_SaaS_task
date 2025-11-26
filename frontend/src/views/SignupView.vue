<template lang="pug">
AuthLayout(
  title="アカウントを作成"
  subtitle="タスク管理ワークスペースをはじめましょう。"
  footer-text="すでにアカウントをお持ちの方は"
  footer-link-to="/login"
  footer-link-label="ログイン"
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
        autocomplete="new-password"
      )

    .form-group
      label.form-label(for="password_conf") パスワード(確認)
      input.form-input#password_conf(
        type="password"
        v-model="form.password_conf"
        placeholder="••••••••"
        autocomplete="new-password"
      )

    p.message.error(v-if="errorMessage") {{ errorMessage }}
    p.message.success(v-if="successMessage") {{ successMessage }}

    button.btn.btn-primary.btn-hover-lift(type="submit" :disabled="isSubmitting")
      span(v-if="isSubmitting") 登録中...
      span(v-else) 登録する
</template>

<script setup>
import { reactive, ref } from "vue";
import { useRouter } from "vue-router";
import { signup } from "@/api/auth";
import AuthLayout from "@/components/AuthLayout.vue";

const router = useRouter();

const form = reactive({
  login_id: "",
  password: "",
  password_conf: "",
});

const errorMessage = ref("");
const successMessage = ref("");
const isSubmitting = ref(false);

const onSubmit = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!form.login_id || !form.password || !form.password_conf) {
    errorMessage.value = "login_id, password, password_conf は必須です。";
    return;
  }

  if (form.password !== form.password_conf) {
    errorMessage.value = "パスワードと確認用パスワードが一致しません。";
    return;
  }

  try {
    isSubmitting.value = true;

    const res = await signup({
      login_id: form.login_id,
      password: form.password,
      password_conf: form.password_conf,
    });

    successMessage.value = res.data?.message || "ユーザー登録が完了しました。";

    setTimeout(() => {
      router.push("/login");
    }, 900);
  } catch (err) {
    const data = err.response?.data;
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value = data?.error || "ユーザー登録に失敗しました。";
    }
  } finally {
    isSubmitting.value = false;
  }
};
</script>