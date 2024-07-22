extends Node

# Global == Domain, SHOULD NOT depend on other classes

enum Event {START, END, RESET}
enum Pos {TOP, BOT}

# CLUSTER values MUST match the dropdown in the dele registry config
enum CLUSTER {CENTRAL,PROD,DEV,OTHER}
const CLUSTERS=["None","prod","dev","other"]

const TRAIL_COLOR:Color = Color("afafff", 1.0)
const TRAIL_COLOR_ALT:Color = Color("ffff0f", 1.0)

const OVERLAY_ZINDEX:int = 20
