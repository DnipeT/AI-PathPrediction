# AI-PathPrediction
Edit: this is deprecated. I have made the better version which unfortunately will not be open-sourced. The new work found is still based on the basics of this repository

![image](https://github.com/DnipeT/AI-PathPrediction/assets/118316586/24041808-9269-487a-b7d0-aaeb4fed828e)


- This is an AI-Path Prediction for Roblox project  which implemented an AI movement prediction around the target to simulate a realistic situation where a target is surrounded by many AI. This creates a path-finding system where AI will try to find an empty 
nearby spots that are close to the target. 
- if available spots that can attack the target are taken( I call them attackable spots), AI/NPC will try to find spots behind attackable spots and get ready to attack (I call them reserve spots) if AI/NPC in attackable spots dies.
- One implementation that could make this better is to have a dynamic scaling distance variable based on the situation. This will make some AI/NPC not stop in the middle because all attackable spots and reserve spots are taken.
