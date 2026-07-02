cask "studybar" do
  version "1.3.0"

  sha256 "705362624dad8e870d1544ed1d365d6d84f6650e1c3caa40c36a9804ab3c0b88"

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
