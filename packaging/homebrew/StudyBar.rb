cask "studybar" do
  version "1.2.0"

  sha256 "d8db093b4f7a903a082d3bded2543c8ec01f357634dd8442814277122ec7a152"

  url "https://github.com/IMisbahk/studybar/releases/download/v#{version}/StudyBar-#{version}.dmg"
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
