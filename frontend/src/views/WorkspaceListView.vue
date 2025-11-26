<template lang="pug">
section.workspace-page
  .workspace-shell
    .workspace-header
      h1.page-title ワークスペース
      p.page-subtitle
        | ログイン中のユーザーが所属しているワークスペースの一覧です。

    //- 作成フォーム
    .card.card-md
      h2.card-title ワークスペースを作成

      form.create-form(@submit.prevent="onCreate")
        .form-group
          label.form-label(for="name") ワークスペース名
          input.name-input#name(
            type="text"
            v-model="name"
            placeholder="例) 開発チーム / 個人タスク用"
          )

        p.message.error(v-if="errorMessage") {{ errorMessage }}
        p.message.success(v-if="successMessage") {{ successMessage }}

        .button-row
          button.btn.btn-primary.btn-hover-lift(type="submit" :disabled="creating")
            span(v-if="creating") 作成中…
            span(v-else) 作成する

    //- リスト
    .card.card-md
      h2.card-title ワークスペース一覧

      div(v-if="loading") 読み込み中…

      ul.workspace-list(v-else)
        li.workspace-item(
          v-for="ws in workspaces"
          :key="ws.id"
          @click="goToWorkspace(ws.id)"
        )
          .ws-name {{ ws.name }}

      p.empty-text(v-if="!loading && workspaces.length === 0")
        | 所属しているワークスペースがありません。
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useRouter } from "vue-router";
import api from "../api/client";

const router = useRouter();

const workspaces = ref([]);
const loading = ref(false);

const name = ref("");
const creating = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const fetchWorkspaces = async () => {
  loading.value = true;
  errorMessage.value = "";
  try {
    const res = await api.get("/workspaces");
    workspaces.value = res.data;
  } catch (err) {
    const status = err.response?.status;
    if (status === 401 || status === 403) {
      router.push("/login");
    } else {
      console.error("ワークスペース一覧取得に失敗しました:", err);
      errorMessage.value = "ワークスペース一覧の取得に失敗しました。";
    }
  } finally {
    loading.value = false;
  }
};

const onCreate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!name.value.trim()) {
    errorMessage.value = "ワークスペース名は必須です。";
    return;
  }

  try {
    creating.value = true;

    const res = await api.post("/workspaces", {
      name: name.value.trim(),
    });

    successMessage.value = res.data.message || "ワークスペースを作成しました。";
    workspaces.value.push(res.data.workspace);
    name.value = "";
  } catch (err) {
    const data = err.response?.data;
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "ワークスペースの作成に失敗しました。";
    }
  } finally {
    creating.value = false;
  }
};

const goToWorkspace = (id) => {
  router.push(`/workspaces/${id}`);
};

onMounted(() => {
  fetchWorkspaces();
});
</script>
