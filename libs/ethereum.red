Red [
	Title:	"Ethereum utility functions"
	Author: "Xie Qingtian"
	File: 	%ethereum.red
	Tabs: 	4
	Rights:  "Copyright (C) 2018 Red Foundation. All rights reserved."
	License: {
		Distributed under the Boost Software License, Version 1.0.
		See https://github.com/red/red/blob/master/BSL-License.txt
	}
]

eth: context [

	ETH-ratio:  to-i256 #{5AF3107A4000}
	GWei-ratio: to-i256 100000

	eth-to-wei: func [eth /local n][
		abc: 2
		if string? eth [eth: to float! eth]
		n: to-i256 to integer! eth * 10000
		mul256 n ETH-ratio
	]

	gwei-to-wei: func [gwei /local n][
		if string? gwei [gwei: to float! gwei]
		n: to-i256 to integer! gwei * 10000
		mul256 n GWei-ratio
	]

	pad64: function [data [string! binary!]][
		n: length? data
		either binary? data [c: #{00} len: 32][c: #"0" len: 64]
		if n < len [
			insert/dup data c len - n
		]
		data
	]

	parse-balance: function [amount][
		either (length? amount) % 2 <> 0 [
			poke amount 2 #"0"
			n: 1
		][n: 2]
		n: to-i256 debase/base skip amount n 16
		n: i256-to-int div256 n ETH-ratio
		n / 10000.0
	]

	get-balance-token: func [network [url!] contract [string!] address [string!] /local body url token-url params reply][
		url: network
		token-url: rejoin ["0x" contract]
		params: make map! 4
		params/to: token-url
		params/data: rejoin ["0x70a08231" pad64 copy skip address 2]

		body: #(
			jsonrpc: "2.0"
			id: 57386342
			method: "eth_call"
		)
		body/params: reduce [params "latest"]
		reply: json/decode write url compose [
			POST
			[
				Content-Type: "application/json"
				Accept: "application/json"
			]
			(to-binary json/encode body)
		]
		parse-balance reply/result
	]

	get-balance: func [network [url!] address [string!] /local url data n][
		url: replace rejoin [
			network {/eth_getBalance?params=["address","latest"]}
		] "address" address
		data: json/decode read url
		parse-balance data/result
	]

	get-nonce: function [network [url!] address [string!]][
		url: replace rejoin [
			network
			{/eth_getTransactionCount?params=["address", "pending"]}
		] "address" address
		data: json/decode read url
		either (length? data/result) % 2 <> 0 [
			poke data/result 2 #"0"
			n: 1
		][n: 2]
		to integer! debase/base skip data/result n 16
	]
]