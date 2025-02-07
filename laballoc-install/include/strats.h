/**
 * @file
 * @brief Module to change the currently used memory algorithm
 */
#ifndef ALLOC_STRATS_H
#define ALLOC_STRATS_H

#include "alloc/types.h"

uint8_t *best_fit(seg_list_head_s *list, size_t size);

uint8_t *worst_fit(seg_list_head_s *list, size_t size);

uint8_t *first_fit(seg_list_head_s *list, size_t size);

uint8_t *next_fit(seg_list_head_s *list, size_t size);

/**
 * @brief Set the address of last addr pointer
 *
 * This function updates the last_addr pointer in case of new allocation or
 * freeing of blocks. Will be called by said functions
 *
 * @param[in] addr Some tail address, or nullptr if no segment is left anymore
 */
void set_last_addr(seg_tail_s *addr);

/**
 * @brief Returns the address of last addr pointer
 *
 * This function returns the last_addr pointer in case of freeing of blocks.
 * Will be called by said functions.
 *
 */
seg_tail_s *get_last_addr();

#endif
