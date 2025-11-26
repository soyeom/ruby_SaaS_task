<template lang="pug">
.card.card-md.task-card
  // ── 헤더
  header.task-header
    p.breadcrumb {{ breadcrumb }}
    input.task-title-input(
      type="text"
      :value="title"
      :placeholder="titlePlaceholder"
      @input="emit('update:title', $event.target.value)"
    )

  form(@submit.prevent="emit('submit')")
    // ── メタ情報（ステータス・カテゴリ・担当者）
    .meta-row
      .meta-field
        label.form-label(for="status") ステータス
        select#status(
          :value="status"
          @change="emit('update:status', $event.target.value)"
        )
          option(value="todo") 未着手
          option(value="doing") 進行中
          option(value="done") 完了

      .meta-field
        label.form-label(for="category") カテゴリ
        input#category(
          type="text"
          :value="category"
          placeholder="例) バグ / 機能 / 調査"
          @input="emit('update:category', $event.target.value)"
        )

      .meta-field
        label.form-label(for="assignee_id") 担当者
        select#assignee_id(
          :value="assigneeId"
          @change="emit('update:assigneeId', $event.target.value)"
        )
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
        rows="5"
        :value="description"
        placeholder="タスクの詳細やメモを記載してください。"
        @input="emit('update:description', $event.target.value)"
      )

    p.message.error(v-if="errorMessage") {{ errorMessage }}
    p.message.success(v-if="successMessage") {{ successMessage }}

    footer.task-footer
      .button-row
        button.btn.btn-primary.btn-hover-lift(type="submit" :disabled="saving")
          span(v-if="saving") {{ submitLoadingLabel }}
          span(v-else) {{ submitLabel }}

        button.btn.btn-danger.btn-hover-lift(
          v-if="showDelete"
          type="button"
          :disabled="deleting"
          @click="emit('delete')"
        )
          span(v-if="deleting") 削除中…
          span(v-else) タスクを削除

        button.btn.btn-gray(type="button" @click="emit('back')")
          | ← ワークスペースに戻る
</template>

<script setup>
const props = defineProps({
  // 값들
  title: String,
  description: String,
  status: {
    type: String,
    default: "todo",
  },
  category: String,
  assigneeId: [String, Number, null],
  members: {
    type: Array,
    default: () => [],
  },

  // 상태
  saving: Boolean,
  deleting: Boolean,
  errorMessage: String,
  successMessage: String,

  // UI 텍스트
  breadcrumb: {
    type: String,
    default: "タスク",
  },
  submitLabel: {
    type: String,
    default: "保存",
  },
  submitLoadingLabel: {
    type: String,
    default: "保存中…",
  },
  titlePlaceholder: {
    type: String,
    default: "タイトル",
  },
  showDelete: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  "update:title",
  "update:description",
  "update:status",
  "update:category",
  "update:assigneeId",
  "submit",
  "delete",
  "back",
]);
</script>