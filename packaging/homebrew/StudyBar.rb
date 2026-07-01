cask "studybar" do
  version "1.0.0"

  sha256 "d4659e2341d842823352dca2c372b8202f526c73d72880834eb885c8bbae6160"

  url "https://github.com/IMisbahk/studybar/releases/download/v#{version}/StudyBar-#{version}.zip"
  name "StudyBar"
  desc "macOS menu bar study timer with live countdown and session history"
  homepage "https://github.com/IMisbahk/studybar"

  depends_on macos: ">= :sonoma"

  app "StudyBar.app"

  zap trash: [
    "~/Library/Application Support/default.store",
    "~/Library/Application Support/default.store-shm",
    "~/Library/Application Support/default.store-wal",
  ]
end
