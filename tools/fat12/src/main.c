#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>
#include <stdlib.h>

#define PrintNewLine() write(1, "\n", 1)
typedef struct BPB{
    uint8_t m_Start[3];
    uint8_t m_OEMIdentifier[8];
    uint16_t m_BytesPerSector;
    uint8_t m_SectorsPerCluster;
    uint16_t m_ReservedSectors;
    uint8_t m_FatCount;
    uint16_t m_RootEntries;
    uint16_t m_TotalSectors;
    uint8_t m_MediaDescriptorType;
    uint16_t m_SectorsPerFAT;
    uint16_t m_SectorsPerTrack;
    uint16_t m_Heads;
    uint32_t m_HiddenSectors;
    uint32_t m_LargeSectorCount;
    // EBPB
    uint8_t m_DriveNumber;
    uint8_t m_WindowsNTFlags;
    uint32_t m_VolumeId;
    uint8_t m_VolumeLabelString[11];
} __attribute__((packed)) BPB;

typedef struct DirectoryEntry{
    uint8_t m_FileName[11];
    uint8_t m_Attributes;
    uint8_t m_Reserved;
    uint8_t m_CreationTime;
    uint16_t m_CreationDate;
    uint16_t m_DateCreated;
    uint16_t m_LastAccessed;
    uint16_t m_Unused;
    uint16_t m_LastModificationTime;
    uint16_t m_LastModificationDate;
    uint16_t m_FirstLogicalCluster;
    uint32_t m_Size;
}__attribute((packed)) DirectoryEntry;

typedef struct CHS{
    uint32_t m_Cylinder;
    uint32_t m_Head;
    uint32_t m_Sector;
} CHS;
char* ReadFile(char* disk, BPB* bpb, DirectoryEntry* entry, char fileName[11]){
    if(entry->m_Size < 1)return NULL;
    bool t = false;
    char* data = (char*)malloc(entry->m_Size);
    size_t currentFilled = 0;
    uint8_t* fatTable = data + bpb->m_BytesPerSector;
    //uint8_t activeCluster = entry
    //mempcpy(data, disk + (bpb->m_FatCount + bpb->m_ReservedSectors) * bpb->m_BytesPerSector, entry->m_Size);
    uint16_t logicalSector = entry->m_FirstLogicalCluster;
    size_t clusterLocation = (bpb->m_SectorsPerFAT * bpb->m_FatCount + bpb->m_ReservedSectors) * bpb->m_BytesPerSector + bpb->m_RootEntries * sizeof(DirectoryEntry); 
    printf("ClusterLocation %u\n", clusterLocation);
    printf("First cluster %u\n", entry->m_FirstLogicalCluster);
    mempcpy(data, disk +clusterLocation + bpb->m_SectorsPerCluster * entry->m_FirstLogicalCluster, 15);
    return data;
}
int CHSToLBS(BPB* bpb, int c, int h, int s){
    return 0;
}
CHS LBAToCHS(BPB* bpb, int lba){
    CHS chs;
    unsigned int s = bpb->m_SectorsPerTrack;
    unsigned int temp = lba / s;
    chs.m_Sector = (lba % s) + 1;
    chs.m_Head = temp % s;
    chs.m_Cylinder = temp / bpb->m_Heads;
    return chs;
}
int main(int argc, char** argv){
    if(argc < 2){
        fprintf(stderr, "bad usage - fat12 filesystem.bin");
        return -1;
    }
    int file = open(argv[1], O_RDONLY);
    if(!file){
        fprintf(stderr, "Failed to open file %s\n", argv[1]);
        return -2;
    }
    printf("Opened fs %s\n", argv[1]);
    off_t size = lseek(file, 0, SEEK_END);
    if(size == -1){
        fprintf(stderr, "Failed to go to end of file\n");
        return -3;
    }
    lseek(file, 0, SEEK_SET);
    char* data = malloc(size);
    struct BPB bpb;
    if(size < 2560){
        fprintf(stderr, "Filesystem is too small, only %u bytes\n", size);
        return -4;
    }
    printf("File size %u\n", size);
    ssize_t bytesRead = read(file, data, size);
    memcpy(&bpb, data, sizeof(struct BPB));

    write(1, bpb.m_OEMIdentifier, 8);
    PrintNewLine();

    write(1, bpb.m_VolumeLabelString, 11);
    PrintNewLine();
    CHS chs1 = LBAToCHS(&bpb, 20);
    printf("LBA 1 %u %u %u\n", chs1.m_Cylinder, chs1.m_Head, chs1.m_Sector);

    printf("Sectors per cluster %u\n", bpb.m_SectorsPerCluster); 
    printf("Fat count %u\n", bpb.m_FatCount); 
    printf("reserved count %u\n", bpb.m_ReservedSectors);
    printf("Sectors per fat %u\n", bpb.m_SectorsPerFAT); 
    printf("Total Sectors %u\n", bpb.m_TotalSectors);
    printf("Sectors track %u\n", bpb.m_SectorsPerTrack);
    printf("Hiden Sectors %u\n", bpb.m_HiddenSectors);
    printf("Media Descriptor Type %X\n", bpb.m_MediaDescriptorType);
    printf("Heads Per Size %u\n", bpb.m_Heads);
    printf("Root Entries %u\n", bpb.m_RootEntries);
    DirectoryEntry* root = (DirectoryEntry*)(data+ (512 * (1 + bpb.m_FatCount * bpb.m_SectorsPerFAT)));

    // Reading Main File
    for(size_t i = 0; i < bpb.m_RootEntries; i++){
        DirectoryEntry* entry = &root[i];
        if(strncmp(entry->m_FileName, "TEST    BIN", 11)){
            continue;
        }
        printf("Got file");
        printf("Data size %d\n", entry->m_Size);
        size_t bytesPerSector = bpb.m_BytesPerSector;
        size_t bytesPerCluster = bpb.m_BytesPerSector * bpb.m_SectorsPerCluster;
        char* fileData = (char*)calloc(sizeof(char), entry->m_Size);
        size_t rootEntryBytes = sizeof(DirectoryEntry) * bpb.m_RootEntries;
        size_t fatOffset = bytesPerSector * bpb.m_ReservedSectors; 
        size_t cluster = entry->m_FirstLogicalCluster;
        size_t clusterIndex = (cluster - 2) * bpb.m_SectorsPerCluster;
        size_t clusterDataOffset = clusterIndex* bytesPerSector;
        size_t dataOffset = bytesPerSector * (bpb.m_ReservedSectors + bpb.m_SectorsPerFAT * bpb.m_FatCount) + rootEntryBytes;
        size_t lba = (bpb.m_ReservedSectors + bpb.m_SectorsPerFAT * bpb.m_FatCount) + (((rootEntryBytes + (bytesPerSector - 1)) / bytesPerSector)) + clusterIndex;
        printf("LBA id is %u\n", lba);
        CHS chs = LBAToCHS(&bpb, lba);
        printf("CHS %u %u %u\n", chs.m_Cylinder, chs.m_Head, chs.m_Sector);
        size_t fileSize = entry->m_Size;
        printf("File size %d\n", fileSize);
        size_t bytesRead = 0;
        size_t currentCluster = cluster;
        printf("FAT at %u\n", fatOffset);
        do{
            printf("Reading cluster %u\n", currentCluster);
            size_t offset = dataOffset + (currentCluster - 2) * bytesPerCluster;
            size_t toRead = fileSize - bytesRead;
            size_t count = toRead >= bytesPerCluster ? bytesPerCluster : toRead;
            printf("Count %u\n", count);
            memcpy(fileData + bytesRead, data + offset, count);
            printf("Bytes Read %u\n", bytesRead);
            bytesRead+=count;
            uint16_t* tableValues = (uint16_t*)fileData;
            size_t fatIndex = currentCluster + (currentCluster / 2);
            printf("Fat offset %u\n", fatIndex);
            uint16_t value = ((uint16_t*)( data+ fatOffset+ fatIndex))[0];
            currentCluster = (currentCluster & 1) ? value >> 4 : value & 0xFFF;
        }while(bytesRead < fileSize);
        printf("\n");
        free(fileData);
    }
    free(data);
    printf("Closing File");
    close(file);
}
