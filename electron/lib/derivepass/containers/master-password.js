'use strict';

const crypto = require('crypto');
const BN = require('bn.js');
const ReactRedux = require('react-redux');
const derivepass = require('../../derivepass');
const MasterPassword = derivepass.components.MasterPassword;
const actions = derivepass.redux.actions;

const KEY_DELAY = 250;

const SMILE = [
  "😀",    "😃",      "😄",    "😆", "😅",    "😂",    "☺️", "😊",
  "😇",    "🙂",   "🙃", "😉", "😌",    "😍",    "😘",      "😗",
  "😙",    "😚",      "😋",    "😜", "😝",    "😛",    "🤑",   "🤗",
  "🤓", "😎",      "😏",    "😒", "😞",    "😔",    "😟",      "😬",
  "🙁", "☹️", "😣",    "😖", "😫",    "😩",    "😤",      "😕",
  "😡",    "😶",      "😐",    "😑", "😯",    "😦",    "😧",      "😮",
  "😲",    "😵",      "😳",    "😨", "😰",    "😢",    "😥",      "😁",
  "😭",    "😓",      "😪",    "😴", "🙄", "🤔", "😠",      "🤐",
  "😷",    "🤒",   "🤕", "😈", "👿",    "👻",    "💀",      "☠️",
  "👽",    "👾",      "🤖", "🎃", "😺",    "😸",    "😹",      "😻",
  "😼",    "😽",      "😿",    "😾"];
const GESTURE = [
  "👐", "👌",      "👏", "🙏",    "👍", "👎", "👊",
  "✊", "✌️", "🙌", "🤘", "👈", "👉", "👆",
  "👇", "☝️", "✋", "🖖", "👋", "💪"];
const ANIMAL = [
  "🐶",    "🐱",    "🐭",    "🐹", "🐰",    "🐻",    "🐼",   "🐨", "🐯", "🦁",
  "🦃", "🐷",    "🐮",    "🐵", "🐒",    "🐔",    "🐧",   "🐦", "🐤", "🐣",
  "🐥",    "🐺",    "🐗",    "🐴", "🦄", "🐝",    "🐛",   "🐌", "🐚", "🐞",
  "🐜",    "🕷", "🐢",    "🐍", "🦂", "🦀", "🐙",   "🐠", "🐟", "🐡",
  "🐬",    "🐳",    "🐋",    "🐊", "🐆",    "🐅",    "🐃",   "🐂", "🐄", "🐪",
  "🐫",    "🐘",    "🐎",    "🐖", "🐐",    "🐏",    "🐑",   "🐕", "🐩", "🐈",
  "🐓",    "🐽",    "🕊", "🐇", "🐁",    "🐀",    "🐿"];
const FOOD = [
  "🍏", "🍎", "🍐",      "🍊", "🍋", "🍌",    "🍉", "🍇", "🍓",    "🍈",    "🍒",
  "🍑", "🍍", "🍅",      "🍆", "🌽", "🌶", "🍠", "🌰", "🍯",    "🍞",    "🧀",
  "🍳", "🍤", "🍗",      "🍖", "🍕", "🌭", "🍔", "🍟", "🌮", "🌯", "🍝",
  "🍜", "🍲", "🍥",      "🍣", "🍱", "🍛",    "🍚", "🍙", "🍘",    "🍢",    "🍡",
  "🍧", "🍨", "🍦",      "🍺", "🎂", "🍮",    "🍭", "🍬", "🍫",    "🍿", "🍩",
  "🍪", "🍰", "☕️", "🍵", "🍶", "🍼",    "🍻", "🍷", "🍸",    "🍹",    "🍾"];
const OBJECT = [
  "⌚️", "📱",      "💻",       "⌨️", "🖥",   "🖨", "🖱",
  "🖲",   "🕹",   "🗜",    "💾",      "💿",      "📼",    "📷",
  "🗑",   "🎞",   "📞",       "☎️", "📟",      "📠",    "📺",
  "📻",      "🎙",   "⏱",       "⌛️", "📡",      "🔋",    "🔌",
  "💡",      "🔦",      "🕯",    "💷",      "🛢",   "💵",    "💴",
  "🎥",      "💶",      "💳",       "💎",      "⚖️", "🔧",    "🔨",
  "🔩",      "⚙️", "🔫",       "💣",      "🔪",      "🗡", "🚬",
  "🔮",      "📿",   "💈",       "⚗️", "🔭",      "🔬",    "🕳",
  "💊",      "💉",      "🌡",    "🚽",      "🚰",      "🛁",    "🛎",
  "🗝",   "🚪",      "🛋",    "🛏",   "🖼",   "🛍", "🎁",
  "🎈",      "🎀",      "🎉",       "✉️", "📦",      "🏷", "📫",
  "📯",      "📜",      "📆",       "📅",      "📇",      "🗃", "🗄",
  "📋",      "📂",      "🗞",    "📓",      "📖",      "🔗",    "📎",
  "📐",      "📌",      "🏳️", "🌈",      "✂️", "🖌", "✏️",
  "🔍",      "🔒",      "🍴"];
const ALPHABET = [ SMILE, GESTURE, ANIMAL, FOOD, OBJECT ];


function mapStateToProps(state) {
  return {
    master: state.master.password,
    emoji: state.master.emoji,
    computing: state.master.computing.status
  };
}

function computeEmoji(value) {
  if (value === '')
    return '😬';

  const text = 'derivepass/' + value;
  const digest = crypto.createHash('sha512').update(text).digest();

  const fingerprint = new BN(digest.slice(0, 8), 'le');

  let out = '';
  for (let i = 0; i < ALPHABET.length; i++) {
    const idx = fingerprint.modn(ALPHABET[i].length);
    fingerprint.idivn(ALPHABET[i].length);

    out += ALPHABET[i][idx];
  }

  return out;
}


function mapDispatchToProps(dispatch, ownProps) {
  let timer = null;
  return function componentMap(dispatch, ownProps) {
    return {
      computeEmoji: computeEmoji,
      onChange: (master, computing) => {
        const emoji = computeEmoji(master);
        if (timer)
          clearTimeout(timer);
        else
          dispatch(actions.setMasterComputing('PENDING', emoji));

        timer = setTimeout(() => {
          timer = null;

          dispatch(actions.setMasterComputing('RUNNING', emoji));
          ownProps.cryptor.deriveKeys(master, () => {
            dispatch(actions.setMasterComputing('READY', emoji));
          });
        }, KEY_DELAY);

        dispatch(actions.updateMaster(master, emoji));
      },
      onSubmit: () => {
        dispatch(actions.selectTab('APPLICATIONS'));
      }
    };
  };
}

module.exports = ReactRedux.connect(mapStateToProps, mapDispatchToProps)(
  MasterPassword
);
