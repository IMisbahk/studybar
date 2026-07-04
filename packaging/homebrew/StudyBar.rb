cask "studybar" do
  version "2.13.0"

  sha256 "e6c2e18d08a1c3a08d086b3c0d8d28fa1af3a6aa4f00034a5183e31077e70af4"

  url "https://github.com/IMisbahk/studybar/releases/download/v#{version}/StudyBar-#{version}.dmg"
  name "StudyBar"
  desc "macOS menu bar study timer with live countdown and session history"
  homepage "https://github.com/IMisbahk/studybar"

  depends_on macos: ">= :sonoma"

  app "StudyBar.app"

  zap trash: [
    "~/Library/Application Support/StudyBar",
  ]
end
