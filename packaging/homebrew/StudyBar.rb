cask "studybar" do
  version "2.14.0"

  sha256 "0c904557eb11b817cd9424fcfa70dea18f7bcf7a37e620f80c42dccaa8805cb3"

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
