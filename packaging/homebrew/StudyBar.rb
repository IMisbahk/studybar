cask "studybar" do
  version "1.0.0"

  sha256 "4a81f1939a1820e152076641c4a599d0721e71fb087e434632500b8d9f4b3032"

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
