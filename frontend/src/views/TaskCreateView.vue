<template lang="pug">
section.task-page
  .task-shell
    .card.card-md.task-card
      // ── 헤더: 제목 입력
      header.task-header
        p.breadcrumb タスク / 新規作成
        input.task-title-input(
          type="text"
          v-model="title"
          placeholder="タイトル"
        )

      form(@submit.prevent="onCreate")
        // ── メタ情報（ステータス・カテゴリ・担当者）
        .meta-row
          .meta-field
            label.form-label(for="status") ステータス
            select#status(v-model="status")
              option(value="todo") 未着手
              option(value="doing") 進行中
              option(value="done") 完了

          .meta-field
            label.form-label(for="category") カテゴリ
            input#category(
              type="text"
              v-model="category"
              placeholder="例) バグ / 機能 / 調査"
            )

          .meta-field
            label.form-label(for="assignee_id") 担当者
            select#assignee_id(v-model="assigneeId")
              option(value="") 担当者なし
              option(
                v-for="m in members"
                :key="m.user ? m.user.id : m.id"
                :value="m.user ? m.user.id : m.id"
              )
                | {{ m.user ? m.user.login_id : m.login_id }}

        // ── 説明
        .form-group
          label.form-label(for="description") 説明
          textarea#description(
            v-model="description"
            rows="5"
            placeholder="タスクの詳細やメモを記載してください。"
          )

        p.message.error(v-if="errorMessage") {{ errorMessage }}
        p.message.success(v-if="successMessage") {{ successMessage }}

        footer.task-footer
          .button-row
            button.btn.btn-primary.btn-hover-lift(type="submit" :disabled="saving")
              span(v-if="saving") 作成中…
              span(v-else) タスクを作成

            button.btn.btn-gray(type="button" @click="goBack")
              | ← ワークスペースに戻る
</template>

<script setup>
import { ref, onMounted } from "vue";
import { useRoute, useRouter } from "vue-router";
import api from "../api/client";

const route = useRoute();
const router = useRouter();

const title = ref("");
const description = ref("");
const status = ref("todo");
const category = ref("");
const assigneeId = ref("");

const members = ref([]);

const saving = ref(false);
const errorMessage = ref("");
const successMessage = ref("");

const workspaceId = () => route.params.workspaceId;

const fetchMembers = async () => {
  try {
    const res = await api.get(`/workspaces/${workspaceId()}`);
    members.value = res.data.members || [];
  } catch (err) {
    console.error("メンバー情報の取得に失敗しました:", err);
  }
};

const onCreate = async () => {
  errorMessage.value = "";
  successMessage.value = "";

  if (!title.value.trim()) {
    errorMessage.value = "タスクタイトルは必須です。";
    return;
  }

  try {
    saving.value = true;

    const res = await api.post(`/workspaces/${workspaceId()}/tasks`, {
      title: title.value.trim(),
      description: description.value.trim(),
      status: status.value,
      category: category.value.trim(),
      assignee_id: assigneeId.value || null,
    });

    successMessage.value = res.data.message || "タスクを作成しました。";

    router.push(`/workspaces/${workspaceId()}`);
  } catch (err) {
    const data = err.response?.data;
    console.error("タスク作成に失敗しました:", err);
    if (data?.details) {
      errorMessage.value = data.details.join(" / ");
    } else {
      errorMessage.value =
        data?.error || "タスクの作成に失敗しました。";
    }
  } finally {
    saving.value = false;
  }
};

const goBack = () => {
  router.push(`/workspaces/${workspaceId()}`);
};

onMounted(() => {
  fetchMembers();
});
</script>