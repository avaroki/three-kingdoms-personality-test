const number = document.getElementById("number");
const questionEl = document.getElementById("question");
let currentQuestion = 0;

// 캐릭터 점수
let scores = {
  유비: 0,
  조조: 0,
  제갈량: 0,
  관우: 0,
  장비: 0,
  손권: 0,
  여포: 0,
  조운: 0,
  주유: 0,
  사마의: 0
};

const characterDescriptions = {
  유비: "당신은 사람을 먼저 생각하고 주변의 마음을 자연스럽게 모으는 타입입니다. 강하게 밀어붙이기보다 함께 가는 방식을 좋아하며, 어려운 상황에서도 관계와 신뢰를 쉽게 포기하지 않습니다.",
  조조: "당신은 상황 판단이 빠르고 목표를 향해 효율적으로 움직이는 타입입니다. 감정보다 현실적인 결과를 중요하게 보고, 필요할 때는 과감한 결정을 내릴 줄 압니다.",
  제갈량: "당신은 차분하게 생각하고 계획적으로 움직이는 지략가입니다. 문제를 감정적으로 보기보다 구조를 파악하고 해결책을 찾는 데 강합니다.",
  관우: "당신은 의리와 신념을 중요하게 생각하는 타입입니다. 한 번 정한 원칙은 쉽게 바꾸지 않고, 어려운 순간에도 품위를 지키려 합니다.",
  장비: "당신은 솔직하고 에너지가 넘치는 돌파형 타입입니다. 마음에 있는 말을 숨기지 않고, 답답한 상황에서는 직접 부딪혀 해결하려는 편입니다.",
  손권: "당신은 분위기를 읽을 줄 아는 균형잡힌 리더입니다. 혼자 앞서가기보다 타인의 말을 경청하고 주변 상황을 살피며 가장 적합한 판단을 내립니다.",
  여포: "당신은 자유롭고 강렬한 에너지를 가진 승부사입니다. 누가 정해준 길보다 자신이 원하는 방향으로 움직이고, 결정적인 순간의 집중력과 추진력이 강합니다.",
  조운: "당신은 조용하지만 책임감 있는 타입입니다. 항상 맡은 일을 묵묵히 완수하고, 위기 상황에서도 쉽게 흔들리지 않습니다.",
  주유: "당신은 감각적이고 자존심이 강한 타입입니다. 타인에게 자연스럽게 매력을 드러내며, 분위기와 미묘한 감정의 흐름을 잘 읽습니다.",
  사마의: "당신은 쉽게 속마음을 드러내지 않고 신중하게 움직이는 관찰자입니다. 당장 반응하기보다 상황을 지켜보며 적절한 타이밍을 기다릴 줄 압니다."
};

const characterImages = {
  유비: "images/liu-bei.png",
  조조: "images/cao-cao.png",
  제갈량: "images/zhuge-liang.png",
  관우: "images/guan-yu.png",
  장비: "images/zhang-fei.png",
  손권: "images/sun-quan.png",
  여포: "images/lu-bu.png",
  조운: "images/zhao-yun.png",
  주유: "images/zhou-yu.png",
  사마의: "images/sima-yi.png"
};

const questions = [
    
  {
    question: "친구들과 여행 가면 나는?",
    answers: [
      { text: "1. 동선, 시간, 비용을 고려해 효율적으로 계획을 짠다", scores: { 조조: 2, 제갈량: 2 } },
      { text: "2. 계획은 다른 사람이 세워주겠지", scores: { 여포: 1, 장비: 1 } },
      { text: "3. 친구들의 의견부터 물어본다", scores: { 유비: 2, 손권: 1 } },
      { text: "4. 계획은 필요없다! 일단 가서 해결한다", scores: { 장비: 2, 여포: 1 } }
    ]
  },

  {
    question: "누가 나를 무시했다",
    answers: [
      { text: "1. 한 대 때려준다", scores: { 장비: 2, 여포: 2 } },
      { text: "2. 논리적으로 반박한다", scores: { 제갈량: 2, 조조: 1 } },
      { text: "3. 웃어 넘기고, 이 일을 마음속에 담아둔다", scores: { 사마의: 2, 주유: 1 } },
      { text: "4. 상대할 필요 없다. 나도 무시한다", scores: { 관우: 2, 조운: 1 } }
    ]
  },

 {
    question: "영화관에 왔다. 어떤 장르의 영화를 볼까?",
    answers: [
      { text: "1. 액션", scores: { 장비: 2, 조운: 1 } },
      { text: "2. 멜로", scores: { 유비: 2, 주유: 1 } },
      { text: "3. 호러", scores: { 사마의: 1, 여포: 1 } },
      { text: "4. 코미디", scores: { 손권: 2, 유비: 1 } }
    ]
  },

 {
    question: "마라톤 시작부터 넘어지고 말았다 어떻게 하겠는가?",
    answers: [
      { text: "1. 포기하지 않고 다시 뛰어나간다", scores: { 조운: 2, 관우: 1 } },
      { text: "2. 주저앉아 엉엉 운다", scores: { 유비: 1, 주유: 1 } },
      { text: "3. 기권한다... ", scores: { 손권: 1, 사마의: 1 } },
      { text: "4. 이 시합 무효야!!", scores: { 장비: 2, 여포: 1 } }
    ]
  },

   {
    question: "당신의 공부 스타일은?",
    answers: [
      { text: "1. 매일 꾸준히", scores: { 조운: 2, 관우: 1 } },
      { text: "2. 계획을 세워서 계획대로 한다", scores: { 제갈량: 2, 조조: 1 } },
      { text: "3. 기분이 내킬 때 한다", scores: { 주유: 1, 여포: 1 } },
      { text: "4. 시험 직전 벼락치기!!!", scores: { 장비: 1, 사마의: 1 } }
    ]
  },

   {
    question: "상사의 농담이 별로 재미가 없다. 그러나 주위의 모든이가 웃고 있다",
    answers: [
      { text: "1. 무표정을 유지한다", scores: { 관우: 2, 조조: 1 } },
      { text: "2. 적당히 따라 웃는다", scores: { 손권: 2, 사마의: 1 } },
      { text: "3. 분위기가 어색해지면 안되지! 박장대소한다", scores: { 유비: 2, 주유: 1 } },
      { text: "4. 재미없다고 솔직히 말한다", scores: { 장비: 2, 여포: 1 } }
    ]
  },

   {
    question: "유명한 레스토랑에 왔다. 어떤 음식을 시킬까",
    answers: [
      { text: "1. 오늘의 추천 메뉴", scores: { 주유: 1, 손권: 1 } },
      { text: "2. 고기와 술을 대령하라", scores: { 장비: 2, 여포: 1 } },
      { text: "3. 영양밸런스와 가격을 고려한다", scores: { 제갈량: 2, 조조: 1 } },
      { text: "4. 다른 사람들이 시키는 메뉴를 보고 따라 시킨다", scores: { 유비: 1, 손권: 2 } }
    ]
  },

   {
    question: "학창 시절, 수업 중 화장실에 가고 싶어졌다",
    answers: [
      { text: "1. 선생님 화장실 다녀오겠습니다!", scores: { 장비: 1, 조운: 1 } },
      { text: "2. 눈치를 보고 슬쩍 다녀온다", scores: { 사마의: 2, 손권: 1 } },
      { text: "3. 수업이 끝날때까지 참는다", scores: { 관우: 2, 조운: 1 } },
      { text: "4. 친구에게 같이 가자고 한다", scores: { 유비: 2, 주유: 1 } }
    ]
  },

   {
    question: "친구가 만들어준 음식이 맛이 없다...어때 맛있어?",
    answers: [
      { text: "1. 냉정하게 분석, 평가한다", scores: { 제갈량: 2, 조조: 1 } },
      { text: "2. 맛없어!!!", scores: { 장비: 2, 여포: 1 } },
      { text: "3. 으..음...맛...있어", scores: { 유비: 2, 손권: 1 } },
      { text: "4. 우회적으로 돌려서 맛을 표현한다", scores: { 조운: 1, 관우: 1 } }
    ]
  },

   {
    question: "길을 걷다가 tv의 깜짝 인터뷰를 받았다",
    answers: [
      { text: "1. 부끄러운 나머지 도망친다", scores: { 사마의: 1, 조운: 1 } },
      { text: "2. 쭈뼛쭈뼛 대답한다", scores: { 유비: 1, 손권: 1 } },
      { text: "3. 차분하게 인터뷰에 응한다", scores: { 제갈량: 1, 관우: 1 } },
      { text: "4. 엄마 나 tv 나왔어!", scores: { 주유: 2, 장비: 1 } }
    ]
  },

];

questions.sort(() => Math.random() - 0.5);

questions.length = 7;

const question = document.getElementById("question");

const answer1 = document.getElementById("answer1");
const answer2 = document.getElementById("answer2");
const answer3 = document.getElementById("answer3");
const answer4 = document.getElementById("answer4");

function showQuestion() {

  number.innerText =
    (currentQuestion + 1) + " / " + questions.length;

  question.innerText =
    questions[currentQuestion].question;

  answer1.innerText =
    questions[currentQuestion].answers[0].text;

  answer2.innerText =
    questions[currentQuestion].answers[1].text;

  answer3.innerText =
    questions[currentQuestion].answers[2].text;

  answer4.innerText =
    questions[currentQuestion].answers[3].text;
}

function addScores(answer) {
  for (const character in answer.scores) {
    scores[character] += answer.scores[character];
  }
}

function showResult() {
  const result = Object.entries(scores).sort((a, b) => b[1] - a[1])[0];
  const character = result[0];

  number.innerText = "결과";
  question.innerHTML =
    "<img src=\"" +
    characterImages[character] +
    "\" alt=\"" +
    character +
    "\" class=\"result-image\"><br>" +
    "당신과 가장 닮은 삼국지 인물은 <br><strong>" +
    character +
    "</strong><br><br>" +
    characterDescriptions[character];

  answer1.style.display = "none";
  answer2.style.display = "none";
  answer3.style.display = "none";
  answer4.style.display = "none";
}

function nextQuestion(answerIndex) {
  addScores(questions[currentQuestion].answers[answerIndex]);

  currentQuestion++;

  if(currentQuestion >= questions.length) {
    showResult();
    return;
  }

  showQuestion();
}

answer1.onclick = () => nextQuestion(0);
answer2.onclick = () => nextQuestion(1);
answer3.onclick = () => nextQuestion(2);
answer4.onclick = () => nextQuestion(3);

showQuestion();
