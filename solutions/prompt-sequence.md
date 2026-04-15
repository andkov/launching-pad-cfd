# Sequence of prompts for exploration

Default: Agent Claude Sonnet 4.6, unless specified otherwise

The following is a draft of suggested prompts to use when evaluating AI model behaviour and performance. 

## Verbatim

What is the historic trend of Income Support caseload? How does breaking it down by BFE and ETW change the story? 

> This prompt typically returns a text in the chat


## Starter 1 - Dynamic Document

Create a dynamic document that responds to the following research questions about the provided data: 

What is the historic trend of Income Support caseload? How does breaking it down by BFE and ETW change the story? 


## Starter 2 - Literate Script

Create a literate script that produces a dynamic document that responds to the following research questions about the provided data: 

What is the historic trend of Income Support caseload? How does breaking it down by BFE and ETW change the story? 

Place solution in ./solutions/starter-2-sonnet-46/ 


## Starter 3 - Literate Script - python

Create a literate script that produces a dynamic document that responds to the following research questions about the provided data: 

What is the historic trend of Income Support caseload? How does breaking it down by BFE and ETW change the story? 

Place solution in ./solutions/starter-3-sonnet-46/ 

## Starter 4 - Literate pair

Create a literate pair of .R + .qmd scripts that produce a dynamic document that responds to the following research questions about the provided data: 

What is the historic trend of Income Support caseload? How does breaking it down by BFE and ETW change the story? 

Place solution in ./solutions/starter-4-sonnet-46/ 

## Site Maker 

Combine html files produced by starter prompts 1 through 4, solutions/prompt-sequence.md, and ./INPUT-manifest.md into a single static website to be housed in ./frontend-1/. 

