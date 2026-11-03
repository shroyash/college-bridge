package com.college.bridge.support.repository;

import com.college.bridge.support.entity.SupportTicket;
import com.college.bridge.support.entity.TicketStatus;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface SupportTicketRepository extends JpaRepository<SupportTicket, Long> {

    Optional<SupportTicket> findByTicketNumber(String ticketNumber);

    List<SupportTicket> findByUserIdOrderByCreatedAtDesc(Long userId);

    @Query("SELECT t FROM SupportTicket t WHERE " +
           "(:status IS NULL OR t.status = :status) AND " +
           "(:search IS NULL OR :search = '' OR " +
           " LOWER(t.ticketNumber) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           " LOWER(t.subject) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           " LOWER(t.description) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           " LOWER(t.userName) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           " LOWER(t.userEmail) LIKE LOWER(CONCAT('%', :search, '%')) OR " +
           " LOWER(t.category) LIKE LOWER(CONCAT('%', :search, '%')))")
    Page<SupportTicket> findByFilter(
            @Param("search") String search,
            @Param("status") TicketStatus status,
            Pageable pageable
    );
}

