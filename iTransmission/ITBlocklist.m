//
//  ITBlocklist.m
//  iTransmission
//
//  Created by user on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ITBlocklist.h"
#import "curl/curl.h"

@implementation ITBlocklist

size_t write_data2(void *ptr, size_t size, size_t nmemb, FILE *stream)
{
    size_t written;
    written = fwrite(ptr, size, nmemb, stream);
    return written;
}

- (void)downloadBlocklist:(NSString *)URL
{
    NSString *charURL = URL; 
    CURL *curl;
    FILE *fp;
    CURLcode res;
    char outfilename[FILENAME_MAX] = "/Applications/iTransmission.app/blocklist";
    const char *url = [charURL UTF8String];
    curl = curl_easy_init();
    if (curl)
    {
        fp = fopen(outfilename,"wb");
        curl_easy_setopt(curl, CURLOPT_URL, url);
        curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, write_data2);
        curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
        res = curl_easy_perform(curl);
            
        curl_easy_cleanup(curl);
        fclose(fp);
    }
}

@end
