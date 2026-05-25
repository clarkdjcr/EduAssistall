import Foundation

// MARK: - Built-in Career & Luminary data (no Firestore required)

struct CareerDataProvider {

    // MARK: - Career Paths

    static let careers: [CareerPath] = [
        CareerPath(
            id: "software-engineer",
            title: "Software Engineer",
            description: "Design and build apps, websites, games, and the systems that power the modern world. Software engineers solve real problems with code.",
            relatedInterests: ["Technology", "Math", "Science", "Gaming", "Computers"],
            educationOptions: [
                EducationOption(id: "se-1", type: .college, name: "Computer Science B.S.", duration: "4 years", estimatedAnnualCost: 35_000, description: "A broad foundation in algorithms, data structures, systems, and software design."),
                EducationOption(id: "se-2", type: .technical, name: "Coding Bootcamp", duration: "6 months", estimatedAnnualCost: 15_000, description: "Intensive, project-based training in web or mobile development."),
                EducationOption(id: "se-3", type: .selfTaught, name: "Online Courses + Projects", duration: "1–2 years", estimatedAnnualCost: 0, description: "Platforms like freeCodeCamp, Coursera, and GitHub let you build skills and a portfolio for free.")
            ],
            averageSalary: "$110,000 / year",
            growthOutlook: "Much faster than average (+25%)",
            icon: "laptopcomputer",
            colorName: "blue"
        ),
        CareerPath(
            id: "marine-biologist",
            title: "Marine Biologist",
            description: "Study ocean ecosystems, marine animals, and the impact of climate on sea life. Field research, lab work, and conservation are all part of the job.",
            relatedInterests: ["Science", "Animals", "Environment", "Nature", "Biology"],
            educationOptions: [
                EducationOption(id: "mb-1", type: .college, name: "Marine Biology B.S.", duration: "4 years", estimatedAnnualCost: 30_000, description: "Covers ecology, zoology, oceanography, and hands-on field research."),
                EducationOption(id: "mb-2", type: .college, name: "Marine Biology M.S. / Ph.D.", duration: "2–6 additional years", estimatedAnnualCost: 20_000, description: "Required for research or university positions. Many programs are funded.")
            ],
            averageSalary: "$67,000 / year",
            growthOutlook: "Average (+6%)",
            icon: "fish.fill",
            colorName: "teal"
        ),
        CareerPath(
            id: "graphic-designer",
            title: "Graphic Designer",
            description: "Create visual identities, illustrations, layouts, and digital art for brands, media, and entertainment.",
            relatedInterests: ["Art", "Technology", "Creativity", "Design", "Media"],
            educationOptions: [
                EducationOption(id: "gd-1", type: .college, name: "Graphic Design B.F.A.", duration: "4 years", estimatedAnnualCost: 32_000, description: "Studio coursework in typography, branding, digital media, and design theory."),
                EducationOption(id: "gd-2", type: .technical, name: "Design Certificate Program", duration: "1 year", estimatedAnnualCost: 10_000, description: "Focused training in tools like Figma, Illustrator, and Photoshop."),
                EducationOption(id: "gd-3", type: .selfTaught, name: "Portfolio + Online Courses", duration: "1 year", estimatedAnnualCost: 500, description: "Many designers are self-taught. A strong portfolio matters more than a degree in many roles.")
            ],
            averageSalary: "$58,000 / year",
            growthOutlook: "Stable (+3%)",
            icon: "paintbrush.fill",
            colorName: "purple"
        ),
        CareerPath(
            id: "physician",
            title: "Physician / Doctor",
            description: "Diagnose and treat illness, injuries, and chronic conditions. Specialize in surgery, pediatrics, psychiatry, family medicine, and more.",
            relatedInterests: ["Science", "Biology", "Helping Others", "Healthcare", "Math"],
            educationOptions: [
                EducationOption(id: "md-1", type: .college, name: "Pre-Med B.S. + Medical School (M.D.)", duration: "8 years", estimatedAnnualCost: 45_000, description: "4-year undergraduate + 4-year medical school, followed by 3–7 years of residency."),
                EducationOption(id: "md-2", type: .college, name: "Doctor of Osteopathic Medicine (D.O.)", duration: "8 years", estimatedAnnualCost: 40_000, description: "Similar to M.D. with additional focus on holistic and musculoskeletal medicine.")
            ],
            averageSalary: "$210,000 / year",
            growthOutlook: "Faster than average (+11%)",
            icon: "stethoscope",
            colorName: "red"
        ),
        CareerPath(
            id: "teacher",
            title: "Educator / Teacher",
            description: "Guide students through learning, spark curiosity, and shape the next generation. Teach any subject — from kindergarten to college.",
            relatedInterests: ["Education", "Helping Others", "Communication", "Leadership", "Kids"],
            educationOptions: [
                EducationOption(id: "te-1", type: .college, name: "Education B.A. / B.S.", duration: "4 years", estimatedAnnualCost: 28_000, description: "Includes student teaching, pedagogy, and subject-area coursework."),
                EducationOption(id: "te-2", type: .technical, name: "Alternative Certification Program", duration: "1 year", estimatedAnnualCost: 5_000, description: "For career-changers who already have a bachelor's degree in their subject area.")
            ],
            averageSalary: "$62,000 / year",
            growthOutlook: "Average (+5%)",
            icon: "book.fill",
            colorName: "orange"
        ),
        CareerPath(
            id: "environmental-scientist",
            title: "Environmental Scientist",
            description: "Protect natural resources, study pollution, and develop solutions to climate and ecological challenges.",
            relatedInterests: ["Science", "Environment", "Nature", "Geography", "Biology"],
            educationOptions: [
                EducationOption(id: "es-1", type: .college, name: "Environmental Science B.S.", duration: "4 years", estimatedAnnualCost: 29_000, description: "Covers ecology, chemistry, geology, and environmental policy."),
                EducationOption(id: "es-2", type: .college, name: "Environmental Science M.S.", duration: "2 additional years", estimatedAnnualCost: 22_000, description: "Specialization in climate science, hydrology, or environmental management.")
            ],
            averageSalary: "$76,000 / year",
            growthOutlook: "Faster than average (+8%)",
            icon: "leaf.fill",
            colorName: "green"
        ),
        CareerPath(
            id: "entrepreneur",
            title: "Entrepreneur",
            description: "Build your own company from an idea. Entrepreneurs identify problems, create solutions, and grow teams and products.",
            relatedInterests: ["Business", "Creativity", "Leadership", "Technology", "Finance"],
            educationOptions: [
                EducationOption(id: "en-1", type: .college, name: "Business / Management B.S.", duration: "4 years", estimatedAnnualCost: 32_000, description: "Business fundamentals: finance, marketing, operations, and strategy."),
                EducationOption(id: "en-2", type: .selfTaught, name: "Start Building Now", duration: "Ongoing", estimatedAnnualCost: 0, description: "Many successful founders dropped out or started before finishing college. Execution matters most.")
            ],
            averageSalary: "Highly variable",
            growthOutlook: "Growing fast",
            icon: "lightbulb.fill",
            colorName: "orange"
        ),
        CareerPath(
            id: "architect",
            title: "Architect",
            description: "Design buildings, spaces, and cities that are beautiful, functional, and safe. Blend art, math, and engineering every day.",
            relatedInterests: ["Math", "Art", "Design", "Engineering", "Creativity"],
            educationOptions: [
                EducationOption(id: "ar-1", type: .college, name: "Architecture B.Arch.", duration: "5 years", estimatedAnnualCost: 38_000, description: "Studio design, structural engineering, history of architecture, and building technology."),
                EducationOption(id: "ar-2", type: .college, name: "Architecture M.Arch.", duration: "3 additional years", estimatedAnnualCost: 40_000, description: "Graduate entry point for students with non-architecture undergraduate degrees.")
            ],
            averageSalary: "$91,000 / year",
            growthOutlook: "Average (+5%)",
            icon: "building.2.fill",
            colorName: "indigo"
        ),
        CareerPath(
            id: "data-scientist",
            title: "Data Scientist",
            description: "Find patterns in massive datasets to guide business decisions, medical research, and AI. Combines statistics, coding, and domain expertise.",
            relatedInterests: ["Math", "Technology", "Science", "Statistics", "Computers"],
            educationOptions: [
                EducationOption(id: "ds-1", type: .college, name: "Statistics or CS B.S.", duration: "4 years", estimatedAnnualCost: 33_000, description: "Strong foundation in statistics, probability, linear algebra, and programming."),
                EducationOption(id: "ds-2", type: .college, name: "Data Science M.S.", duration: "2 additional years", estimatedAnnualCost: 25_000, description: "Many data science roles prefer or require a master's degree."),
                EducationOption(id: "ds-3", type: .selfTaught, name: "Kaggle + Online Courses", duration: "1 year", estimatedAnnualCost: 0, description: "Kaggle competitions and free courses on Coursera / fast.ai build practical skills quickly.")
            ],
            averageSalary: "$120,000 / year",
            growthOutlook: "Much faster than average (+36%)",
            icon: "chart.bar.fill",
            colorName: "cyan"
        ),
        CareerPath(
            id: "nurse",
            title: "Registered Nurse",
            description: "Provide direct patient care, coordinate treatments, and support patients and families through medical challenges.",
            relatedInterests: ["Healthcare", "Helping Others", "Science", "Biology", "Communication"],
            educationOptions: [
                EducationOption(id: "rn-1", type: .college, name: "Nursing B.S.N.", duration: "4 years", estimatedAnnualCost: 28_000, description: "Clinical training combined with coursework in anatomy, pharmacology, and patient care."),
                EducationOption(id: "rn-2", type: .technical, name: "Associate Degree in Nursing (ADN)", duration: "2 years", estimatedAnnualCost: 12_000, description: "Faster path to RN licensure. Many nurses start with ADN and bridge to BSN later.")
            ],
            averageSalary: "$80,000 / year",
            growthOutlook: "Much faster than average (+15%)",
            icon: "heart.fill",
            colorName: "red"
        ),
        CareerPath(
            id: "journalist",
            title: "Journalist / Writer",
            description: "Investigate stories, report the news, write books, or create content that informs and connects communities.",
            relatedInterests: ["Writing", "Communication", "Social Issues", "History", "Media"],
            educationOptions: [
                EducationOption(id: "jw-1", type: .college, name: "Journalism or English B.A.", duration: "4 years", estimatedAnnualCost: 30_000, description: "Reporting, editing, media ethics, and writing across platforms."),
                EducationOption(id: "jw-2", type: .selfTaught, name: "Start Writing Online", duration: "Ongoing", estimatedAnnualCost: 0, description: "Blogs, Medium, and local outlets all provide opportunities to build a byline portfolio.")
            ],
            averageSalary: "$55,000 / year",
            growthOutlook: "Declining in print, growing in digital",
            icon: "newspaper.fill",
            colorName: "brown"
        ),
        CareerPath(
            id: "ai-ml-engineer",
            title: "AI / Machine Learning Engineer",
            description: "Design, train, and deploy AI models that power products used by millions — from recommendation engines to medical diagnosis tools and autonomous vehicles.",
            relatedInterests: ["Artificial Intelligence", "Technology", "Math", "Coding", "Computers", "Science"],
            educationOptions: [
                EducationOption(id: "ai-1", type: .college, name: "Computer Science or AI B.S.", duration: "4 years", estimatedAnnualCost: 35_000, description: "Core courses in machine learning, linear algebra, probability, and software engineering."),
                EducationOption(id: "ai-2", type: .college, name: "AI / Machine Learning M.S.", duration: "2 additional years", estimatedAnnualCost: 30_000, description: "Deep specialization in neural networks, NLP, computer vision, or reinforcement learning."),
                EducationOption(id: "ai-3", type: .selfTaught, name: "Online Courses + Kaggle", duration: "1–2 years", estimatedAnnualCost: 0, description: "Fast.ai, Coursera Deep Learning Specialization, and Kaggle competitions build real, portfolio-ready skills for free.")
            ],
            averageSalary: "$145,000 / year",
            growthOutlook: "Explosive (+40%)",
            icon: "brain.head.profile",
            colorName: "indigo"
        ),
        CareerPath(
            id: "ai-ethics-analyst",
            title: "AI Ethics & Policy Analyst",
            description: "Ensure AI systems are fair, safe, and accountable. Work at tech companies, governments, or nonprofits to shape the rules for responsible AI development.",
            relatedInterests: ["Artificial Intelligence", "Social Issues", "Law", "Psychology", "Technology", "Writing"],
            educationOptions: [
                EducationOption(id: "ae-1", type: .college, name: "Philosophy, Law, or Public Policy B.A.", duration: "4 years", estimatedAnnualCost: 30_000, description: "Ethics, logic, policy analysis, and technology law. A technical minor in CS strengthens applications."),
                EducationOption(id: "ae-2", type: .college, name: "Technology Policy M.S. / J.D.", duration: "2–3 additional years", estimatedAnnualCost: 35_000, description: "Graduate study in AI governance, privacy law, or human-computer interaction policy.")
            ],
            averageSalary: "$95,000 / year",
            growthOutlook: "Rapidly growing (new field)",
            icon: "scale.3d",
            colorName: "purple"
        ),
        CareerPath(
            id: "prompt-engineer",
            title: "AI Product Specialist / Prompt Engineer",
            description: "Bridge AI capability and real-world use. Design prompts, workflows, and products that make AI tools useful, safe, and effective for specific industries.",
            relatedInterests: ["Artificial Intelligence", "Technology", "Writing", "Business", "Communication", "Creativity"],
            educationOptions: [
                EducationOption(id: "pe-1", type: .college, name: "Computer Science or Linguistics B.S.", duration: "4 years", estimatedAnnualCost: 33_000, description: "Understanding of both language systems and software makes prompt engineers most effective."),
                EducationOption(id: "pe-2", type: .selfTaught, name: "Online Courses + AI Tool Practice", duration: "6–12 months", estimatedAnnualCost: 0, description: "Learn prompt design through hands-on experimentation with LLMs, GPTs, and AI APIs — many top practitioners are self-taught.")
            ],
            averageSalary: "$110,000 / year",
            growthOutlook: "Emerging, high demand",
            icon: "text.bubble.fill",
            colorName: "cyan"
        ),
        CareerPath(
            id: "robotics-engineer",
            title: "Robotics Engineer",
            description: "Build machines that sense the world, make decisions, and take physical action — from surgical robots and warehouse automation to self-driving vehicles and drones.",
            relatedInterests: ["Robotics", "Engineering", "Artificial Intelligence", "Math", "Science", "Technology"],
            educationOptions: [
                EducationOption(id: "re-1", type: .college, name: "Mechanical or Electrical Engineering B.S.", duration: "4 years", estimatedAnnualCost: 36_000, description: "Core mechanical, electrical, and software engineering with electives in robotics and control systems."),
                EducationOption(id: "re-2", type: .college, name: "Robotics Engineering M.S.", duration: "2 additional years", estimatedAnnualCost: 32_000, description: "Specialized graduate programs in autonomous systems, human-robot interaction, or industrial automation.")
            ],
            averageSalary: "$105,000 / year",
            growthOutlook: "Much faster than average (+22%)",
            icon: "gearshape.2.fill",
            colorName: "orange"
        ),
        CareerPath(
            id: "cybersecurity-analyst",
            title: "Cybersecurity Analyst",
            description: "Defend networks, data, and AI systems against attacks. As AI powers more of our world, securing it becomes one of the most critical and in-demand jobs.",
            relatedInterests: ["Cybersecurity", "Technology", "Coding", "Math", "Artificial Intelligence", "Engineering"],
            educationOptions: [
                EducationOption(id: "ca-1", type: .college, name: "Cybersecurity or CS B.S.", duration: "4 years", estimatedAnnualCost: 30_000, description: "Network security, cryptography, ethical hacking, and systems engineering."),
                EducationOption(id: "ca-2", type: .technical, name: "Security Certifications (CompTIA, CISSP)", duration: "6–12 months", estimatedAnnualCost: 3_000, description: "Industry certifications are highly valued alongside or instead of a degree for many analyst roles.")
            ],
            averageSalary: "$112,000 / year",
            growthOutlook: "Much faster than average (+32%)",
            icon: "lock.shield.fill",
            colorName: "red"
        ),
        CareerPath(
            id: "chef",
            title: "Chef / Culinary Arts",
            description: "Create memorable dining experiences through flavors, technique, and presentation. Work in restaurants, catering, or run your own food business.",
            relatedInterests: ["Food", "Creativity", "Culture", "Art", "Science"],
            educationOptions: [
                EducationOption(id: "ch-1", type: .vocational, name: "Culinary Arts Certificate / A.A.S.", duration: "1–2 years", estimatedAnnualCost: 18_000, description: "Hands-on kitchen training in technique, baking, and cuisine."),
                EducationOption(id: "ch-2", type: .college, name: "Culinary Institute B.S.", duration: "4 years", estimatedAnnualCost: 35_000, description: "Full culinary arts program with business management and food science."),
                EducationOption(id: "ch-3", type: .selfTaught, name: "Apprenticeship / Kitchen Work", duration: "2–4 years", estimatedAnnualCost: 0, description: "Many great chefs learned by working their way up from dishwasher to line cook to head chef.")
            ],
            averageSalary: "$56,000 / year",
            growthOutlook: "Faster than average (+15%)",
            icon: "fork.knife",
            colorName: "orange"
        )
    ]

    // MARK: - Luminaries

    static let luminaries: [Luminary] = [
        Luminary(
            id: "marie-curie",
            name: "Marie Curie",
            field: "Physics & Chemistry",
            bio: "Marie Curie was the first woman to win a Nobel Prize — and the only person to win Nobel Prizes in two different sciences (Physics and Chemistry). Born in Poland, she conducted groundbreaking research on radioactivity and discovered two elements: polonium and radium.",
            quote: "Nothing in life is to be feared, it is only to be understood. Now is the time to understand more, so that we may fear less.",
            relatedInterests: ["Science", "Chemistry", "Physics", "Math", "Research"],
            icon: "atom"
        ),
        Luminary(
            id: "malala-yousafzai",
            name: "Malala Yousafzai",
            field: "Education & Advocacy",
            bio: "Malala survived an assassination attempt by the Taliban for speaking out about girls' education in Pakistan. She went on to become the youngest Nobel Peace Prize laureate and founded the Malala Fund to champion girls' education worldwide.",
            quote: "One child, one teacher, one book, one pen can change the world.",
            relatedInterests: ["Education", "Helping Others", "Social Issues", "Leadership", "Communication"],
            icon: "book.fill"
        ),
        Luminary(
            id: "ada-lovelace",
            name: "Ada Lovelace",
            field: "Mathematics & Computing",
            bio: "Ada Lovelace is often called the world's first computer programmer. In the 1840s, she wrote the first algorithm intended to be processed by a machine — Charles Babbage's Analytical Engine. She saw the potential of computing a century before computers were built.",
            quote: "That brain of mine is something more than merely mortal, as time will show.",
            relatedInterests: ["Math", "Technology", "Science", "Computers", "Logic"],
            icon: "function"
        ),
        Luminary(
            id: "maya-angelou",
            name: "Maya Angelou",
            field: "Literature & Poetry",
            bio: "Maya Angelou was an American poet, memoirist, and civil rights activist. Her autobiography 'I Know Why the Caged Bird Sings' is celebrated worldwide. She recited her poem 'On the Pulse of Morning' at President Clinton's inauguration.",
            quote: "You may encounter many defeats, but you must not be defeated. It may even be necessary to encounter the defeats, so you can know who you are, what you can rise from, how you can still come out of it.",
            relatedInterests: ["Writing", "Art", "Social Issues", "History", "Communication"],
            icon: "text.quote"
        ),
        Luminary(
            id: "neil-degrasse-tyson",
            name: "Neil deGrasse Tyson",
            field: "Astrophysics & Science Communication",
            bio: "Neil deGrasse Tyson is an astrophysicist, author, and science communicator who has made space and physics accessible to millions through books, TV shows, and his podcast StarTalk. He directed the Hayden Planetarium in New York City.",
            quote: "The universe is under no obligation to make sense to you.",
            relatedInterests: ["Science", "Astronomy", "Math", "Technology", "Communication"],
            icon: "moon.stars.fill"
        ),
        Luminary(
            id: "greta-thunberg",
            name: "Greta Thunberg",
            field: "Climate Activism",
            bio: "Greta Thunberg began striking outside the Swedish parliament at age 15 to demand action on climate change. She sparked the global Fridays for Future movement, spoke at the UN, and became one of the most recognized climate voices in the world.",
            quote: "I have learned that you are never too small to make a difference.",
            relatedInterests: ["Environment", "Science", "Social Issues", "Leadership", "Nature"],
            icon: "leaf.fill"
        ),
        Luminary(
            id: "steve-jobs",
            name: "Steve Jobs",
            field: "Technology & Design",
            bio: "Steve Jobs co-founded Apple and led the creation of products that redefined personal computing, music, phones, and tablets. He believed deeply that technology and the liberal arts must intersect to create magical products.",
            quote: "Stay hungry, stay foolish.",
            relatedInterests: ["Technology", "Design", "Creativity", "Business", "Art"],
            icon: "applelogo"
        ),
        Luminary(
            id: "oprah-winfrey",
            name: "Oprah Winfrey",
            field: "Media & Philanthropy",
            bio: "Oprah Winfrey rose from a difficult childhood in rural Mississippi to become one of the most influential media figures in history. She built a global media empire, is a major philanthropist, and has opened doors for countless writers, educators, and entrepreneurs.",
            quote: "The biggest adventure you can take is to live the life of your dreams.",
            relatedInterests: ["Communication", "Business", "Helping Others", "Media", "Leadership"],
            icon: "mic.fill"
        ),
        Luminary(
            id: "leonardo-da-vinci",
            name: "Leonardo da Vinci",
            field: "Art, Science & Engineering",
            bio: "Leonardo da Vinci was the ultimate Renaissance person — painter of the Mona Lisa, anatomist, engineer, architect, and inventor. His notebooks are filled with flying machines and anatomical drawings that were 400 years ahead of their time.",
            quote: "Learning never exhausts the mind.",
            relatedInterests: ["Art", "Science", "Engineering", "Creativity", "Design", "Math"],
            icon: "paintpalette.fill"
        ),
        Luminary(
            id: "katherine-johnson",
            name: "Katherine Johnson",
            field: "Mathematics & Space",
            bio: "Katherine Johnson was a NASA mathematician whose precise orbital mechanics calculations were critical to the success of the first U.S. crewed spaceflights. Her story was featured in the film 'Hidden Figures.'",
            quote: "Like what you do, and then you will do your best.",
            relatedInterests: ["Math", "Science", "Technology", "Astronomy", "Engineering"],
            icon: "star.fill"
        ),
        Luminary(
            id: "joy-buolamwini",
            name: "Joy Buolamwini",
            field: "AI Ethics & Algorithmic Justice",
            bio: "Joy Buolamwini is a computer scientist, poet of code, and founder of the Algorithmic Justice League. While at MIT, she discovered that leading facial recognition systems were dramatically less accurate for darker-skinned faces, exposing systemic bias in AI. Her research sparked policy changes at major tech companies and a global conversation about fairness in AI.",
            quote: "The future of AI is not something that just happens to us — it is something we choose.",
            relatedInterests: ["Artificial Intelligence", "Social Issues", "Technology", "Engineering", "Law"],
            icon: "person.fill.viewfinder"
        ),
        Luminary(
            id: "fei-fei-li",
            name: "Fei-Fei Li",
            field: "Computer Vision & AI for Good",
            bio: "Fei-Fei Li is a Stanford professor who co-created ImageNet — the massive image dataset that sparked the modern deep learning revolution. She co-directs the Stanford Human-Centered AI Institute (HAI) and is a leading voice for AI that benefits humanity. She also co-founded AI4ALL, a nonprofit expanding access to AI education for underrepresented students.",
            quote: "There is nothing artificial about AI. It is inspired by people, it is created by people, and — most importantly — it impacts people.",
            relatedInterests: ["Artificial Intelligence", "Science", "Technology", "Math", "Helping Others", "Education"],
            icon: "eye.fill"
        ),
        Luminary(
            id: "geoffrey-hinton",
            name: "Geoffrey Hinton",
            field: "Deep Learning & AI Safety",
            bio: "Geoffrey Hinton is often called the 'Godfather of Deep Learning.' His decades of research on neural networks laid the foundation for modern AI — from voice assistants to medical imaging AI. In 2023 he left Google to speak more freely about the potential risks of AI, becoming one of the field's most prominent advocates for careful, responsible development.",
            quote: "I console myself with the thought that, if we do eventually create super-intelligent beings, perhaps they will be better than us.",
            relatedInterests: ["Artificial Intelligence", "Science", "Math", "Technology", "Engineering"],
            icon: "brain.fill"
        )
    ]

    // MARK: - Filtering

    static func careers(matchingInterests interests: [String]) -> [CareerPath] {
        if interests.isEmpty { return careers }
        return careers
            .filter { $0.matchScore(interests: interests) > 0 }
            .sorted { $0.matchScore(interests: interests) > $1.matchScore(interests: interests) }
    }

    static func luminaries(matchingInterests interests: [String]) -> [Luminary] {
        if interests.isEmpty { return luminaries }
        return luminaries
            .filter { $0.matchScore(interests: interests) > 0 }
            .sorted { $0.matchScore(interests: interests) > $1.matchScore(interests: interests) }
    }
}
