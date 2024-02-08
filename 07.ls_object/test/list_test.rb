# frozen_string_literal: true

require 'minitest/autorun'

class ListTest < Minitest::Test
  # 指定したディレクトリにあるファイルとディレクトリ分FileEntryオブジェクトを生成する
  # ディレクトリ指定（ファイル指定）しない場合はカレントディレクトリからFileEntryオブジェクトを生成する
  # -lを使った場合はロングフォーマットを使って結果を表示する
  # -lがない場合はFileEntryオブジェクトを取得した分のエントリを表示する
end
