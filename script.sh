# Translator
endpointUri='https://trls-ac-ae-001.cognitiveservices.azure.com/'
apiKey='***'
docker run --rm -it -p 5001:5000 --memory 12g --cpus 4 \
    -v /mnt/c/data/TranslatorContainer:/usr/local/models \
    -e apikey=$apiKey \
    -e eula=accept \
    -e billing=$endpointUri \
    -e Languages=en,fr,es,ar,ru \
    localhost:8090/library/mcr.microsoft.com/azure-cognitive-services/translator/text-translation:latest
    # mcr.microsoft.com/azure-cognitive-services/translator/text-translation:latest

docker pull mcr.microsoft.com/azure-cognitive-services/diagnostic
docker run --rm mcr.microsoft.com/azure-cognitive-services/diagnostic \
    eula=accept \
    Billing=$endpointUri \
    ApiKey=$apiKey
