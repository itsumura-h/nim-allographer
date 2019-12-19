import logging

proc logger(output:any) =
  let path = "/home/www/hoteLog.log"
  let logger = newRollingFileLogger(path,mode=fmAppend, fmtStr=verboseFmtStr)
  logger.log(lvlInfo, $output)

var a = "11111111111111111111111"
logger(a)

a = "22222222222222222222222222222222222222222222222222222222"
logger(a)

a = """I, [2019-12-19T08:45:34] -- run: INSERT INTO users (name, email, password, salt, auth_id) VALUES ("user1", "user1@gmail.com", "$2a$10$AnCjZ1nCRHHqBkpCKiUO.uviWNgxCJsIfwauEYgc6Xk0dkgHO4h.2", "$2a$10$AnCjZ1nCRHHqBkpCKiUO.u", 2), ("user2", "user2@gmail.com", "$2a$10$p4koOg3JC9IN.mizpuEC9u0g.hgjpLdpMzNbXhy386WsIi/TmeRqK", "$2a$10$p4koOg3JC9IN.mizpuEC9u", 1), ("user3", "user3@gmail.com", "$2a$10$K.BJVWWtFhMCD1oJgJBp5eMvMh84FTnNxHmTJ3mfVyEbwQAJlVUju", "$2a$10$K.BJVWWtFhMCD1oJgJBp5e", 2), ("user4", "user4@gmail.com", "$2a$10$iG1ejGtJiW5iszBbU5o/8u8aQOf1iNNEJ6SBjdycPFDoloGViFnjW", "$2a$10$iG1ejGtJiW5iszBbU5o/8u", 1), ("user5", "user5@gmail.com", "$2a$10$W86hPUV1ZgkumexBDwiiQ.9Xj6DVOXJuUNKkpwR.MRxR1z1wt9m2u", "$2a$10$W86hPUV1ZgkumexBDwiiQ.", 2), ("user6", "user6@gmail.com", "$2a$10$Ath/UgccbnfNm.UHA4FkcuNWPcVz6JZfB70yVNvmhbk0sG4RjYMCm", "$2a$10$Ath/UgccbnfNm.UHA4Fkcu", 1), ("user7", "user7@gmail.com", "$2a$10$GSiRwNiVGyL1e77vL09yFuvYBUj0GFf.K2RmH1FyUqjVvmHJ4sfV2", "$2a$10$GSiRwNiVGyL1e77vL09yFu", 2), ("user8", "user8@gmail.com", "$2a$10$TYklXVUIsaDxfOddO0yWZOKw6Upk2yYwTCs88G0GeSIx01z1CNbae", "$2a$10$TYklXVUIsaDxfOddO0yWZO", 1), ("user9", "user9@gmail.com", "$2a$10$qTCO7FSCCGWMUlo5Yse4SeWHrBJOH9HLBjH554dS3rUgLQy1xX8z6", "$2a$10$qTCO7FSCCGWMUlo5Yse4Se", 2), ("user10", "user10@gmail.com", "$2a$10$Fu0e.E3URawDTlYgJRnzfubNipSASGo9OPJFKmumRf7nF/veFHNBG", "$2a$10$Fu0e.E3URawDTlYgJRnzfu", 1), ("user11", "user11@gmail.com", "$2a$10$E9uTDVeyH0W1kVJrLRQLou2Nk1M6lahxhlsptIbzMapUT1UstOOP.", "$2a$10$E9uTDVeyH0W1kVJrLRQLou", 2), ("user12", "user12@gmail.com", "$2a$10$c27LZTQ8KXE0bViwPFUhR.rZq1/2I.YLwmXSmzNNr6rcugxlTB.5C", "$2a$10$c27LZTQ8KXE0bViwPFUhR.", 1), ("user13", "user13@gmail.com", "$2a$10$8XAI6TFrjYAAGJPL3mvKK.zMd9mrw7kM0BCdl.RYEdte0iqicjGU6", "$2a$10$8XAI6TFrjYAAGJPL3mvKK.", 2), ("user14", "user14@gmail.com", "$2a$10$hilAIb3HrLFXOcamAV4RNe82pyXJKQD6//rkwYurPuT7.WSTOivCi", "$2a$10$hilAIb3HrLFXOcamAV4RNe", 1), ("user15", "user15@gmail.com", "$2a$10$ChEdfUp3.lFeb89CYs3Yqu.DHqxrV6O2tFMpsibdrbIKIopNtNZk2", "$2a$10$ChEdfUp3.lFeb89CYs3Yqu", 2), ("user16", "user16@gmail.com", "$2a$10$nnAHrJ7NzynY3V81.HgJPuS6kbw5tJmx9kwvc7wFc9SqtoKt0.Mcm", "$2a$10$nnAHrJ7NzynY3V81.HgJPu", 1), ("user17", "user17@gmail.com", "$2a$10$ocN/MgDPg/X5MTj/3qYqeOdn9qI6TNPQOOfMzsuQVNw6zvXYekyiO", "$2a$10$ocN/MgDPg/X5MTj/3qYqeO", 2), ("user18", "user18@gmail.com", "$2a$10$r1LPtmLYHXzCL4fXHgA4...TJqNEtWgCQkXOJmsx2BldzfmviJ1um", "$2a$10$r1LPtmLYHXzCL4fXHgA4..", 1), ("user19", "user19@gmail.com", "$2a$10$59F/mBk4yq3H.BRcJJZZpu2VqIGEk2XT5l74sAB6LDcaEAg6VTrD6", "$2a$10$59F/mBk4yq3H.BRcJJZZpu", 2), ("user20", "user20@gmail.com", "$2a$10$CDttxgwtnq7gpYTXg4IeveBaMBIlx5WDZWfOuN1P8pZ1VqBKzk.Ay", "$2a$10$CDttxgwtnq7gpYTXg4Ieve", 1)"""
logger(a)

a = "444444444444444444444444444444444444444444444444444444444"
logger(a)