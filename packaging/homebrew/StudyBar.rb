cask "studybar" do
  version "1.6.4"

  sha256 "2a84797fb7cc74fac68692e03e828657ccc567ad651c2c358a9a9f194cfe0f43"

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
