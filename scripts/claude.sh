#!/bin/bash

# 引数チェック
if [ $# -ne 1 ]; then
	echo "使用方法: $0 <番号>"
	echo "例: $0 00"
	exit 1
fi

INPUT_FILE="tmp/topics/topics_$1"

# ベースプロンプトを読み込む
if [ ! -f "prompts/rules.md" ]; then
	echo "エラー: prompts/rules.md が見つかりません"
	exit 1
fi
BASE_PROMPT=$(<prompts/rules.md)

# ファイル存在チェック
if [ ! -f "$INPUT_FILE" ]; then
	echo "エラー: ファイル $INPUT_FILE が見つかりません"
	exit 1
fi

echo "処理開始: $INPUT_FILE"

# CSVファイルを1行ずつ処理（標準入力を別のFDに）
exec 3<"$INPUT_FILE"
while IFS=',' read -r title category slug <&3; do
	# 空行をスキップ
	if [ -z "$title" ] || [ -z "$category" ] || [ -z "$slug" ]; then
		continue
	fi

	echo "処理中: $title (カテゴリ: $category, slug: $slug)"

	# 出力ディレクトリを作成
	output_dir="articles/$category"
	mkdir -p "$output_dir"

	# 出力ファイルパス
	output_file="$output_dir/${slug}.md"

	# プロンプトを構築
	prompt="$BASE_PROMPT

## 対象技術
$title (category: $category, slug: $slug)

## 出力要件
- UTF-8エンコーディングで日本語マークダウン形式で出力
- ファイルパス: $output_file

## 指示
上記の技術について、技術ドキュメント作成ルールに従って解説を作成し、指定されたファイルパスに保存してください。"

	echo "出力ファイル: $output_file"

	# claudeコマンドを実行（標準入力を/dev/nullにリダイレクト）
	~/.asdf/installs/nodejs/23.10.0/bin/claude --dangerously-skip-permissions --model opus -p "$prompt" </dev/null

	# ファイルが生成されたか確認
	if [ -f "$output_file" ]; then
		echo "ファイル生成成功: $output_file"
	else
		echo "警告: ファイルが生成されませんでした: $output_file"
	fi

	# Git操作を実行
	git add .
	git commit -m "Add article: $slug"
	git push
	
	# API制限対策のため少し待機
	sleep 2
done
exec 3<&-

echo "処理が完了しました: $INPUT_FILE"
